import 'dart:math' as math;

import '../models/pitch_evaluation.dart';
import '../models/raga.dart';
import '../models/swara.dart';

/// Names frequencies relative to Sa and grades them against expected swaras.
///
/// Live naming chooses the nearest pitch position using the raga's spelling.
/// Grading accepts the expected swara within the configured percentage window.
class SwaraIdentifier {
  const SwaraIdentifier({
    required this.saHz,
    required this.scale,
    this.tolerancePercent = defaultTolerancePercent,
  });

  static const defaultTolerancePercent = 1.5;
  static const maxTolerancePercent = 3.0;

  final double saHz;
  final RagaScale scale;
  final double tolerancePercent;

  /// Finds the nearest swarasthana to [frequencyHz] in any octave.
  IdentifiedSwara identify(double frequencyHz) {
    // The equal-tempered grid only narrows the search; actual swara ratios can
    // differ, so compare against the raga's positions in cents.
    final cents = centsForRatio(frequencyHz / saHz);
    final estimate = (cents / 100).round();

    var bestPosition = estimate;
    var bestOffset = double.infinity;
    for (var position = estimate - 2; position <= estimate + 2; position++) {
      final offset = cents - centsForRatio(swaraPositionRatio(position));
      if (offset.abs() < bestOffset.abs()) {
        bestOffset = offset;
        bestPosition = position;
      }
    }

    final octave = (bestPosition / 12).floor();
    return IdentifiedSwara(
      note: SwaraNote(scale.swaraAt(bestPosition), octave),
      frequencyHz: frequencyHz,
      centsOff: bestOffset,
      inRaga: scale.containsPosition(bestPosition),
    );
  }

  /// Compares a sung frequency against [expected]. Octave is ignored so
  /// that students may sing in a comfortable register.
  StepPitchEvaluation evaluate({
    required int stepIndex,
    required SwaraNote expected,
    required double? sungFrequencyHz,
  }) {
    final expectedHz = expected.frequencyFor(saHz);
    if (sungFrequencyHz == null || sungFrequencyHz <= 0) {
      return StepPitchEvaluation(
        stepIndex: stepIndex,
        expected: expected,
        expectedFreqHz: expectedHz,
        status: NoteMatchStatus.noVoice,
        message: 'No steady voice detected for ${expected.label}',
      );
    }

    final heard = identify(sungFrequencyHz);
    final samePosition = heard.note.swara.position == expected.swara.position;
    // Find the closest octave of the target independently of the detected note.
    // A wide window can extend past the midpoint to a neighboring swara.
    final octaveShift = (math.log(sungFrequencyHz / expectedHz) / math.ln2)
        .round();
    final target = SwaraNote(expected.swara, expected.octave + octaveShift);
    final targetHz = target.frequencyFor(saHz);
    final errorPercent = 100 * (sungFrequencyHz - targetHz).abs() / targetHz;
    // Include the boundary despite floating-point rounding in the ratios.
    final matches = errorPercent <= tolerancePercent + 1e-9;
    final offset = matches
        ? centsForRatio(sungFrequencyHz / targetHz)
        : heard.centsOff;

    final (status, message) = matches
        ? (NoteMatchStatus.match, 'Matched within pitch tolerance')
        : !samePosition
        ? (
            NoteMatchStatus.wrongSwara,
            'Sang ${heard.note.label} (${heard.note.fullName}) instead of '
                '${expected.label}',
          )
        : (
            NoteMatchStatus.apasruti,
            '${expected.label} was a little too ${offset > 0 ? 'high' : 'low'}.',
          );

    return StepPitchEvaluation(
      stepIndex: stepIndex,
      expected: expected,
      expectedFreqHz: expectedHz,
      sung: matches
          ? target
          : samePosition
          ? SwaraNote(expected.swara, heard.note.octave)
          : heard.note,
      sungFreqHz: sungFrequencyHz,
      centDeviation: offset.round(),
      status: status,
      message: message,
    );
  }
}

/// Robust pitch for one sung step.
///
/// Settled notes discard the attack; marked or detected glides use the tail
/// to represent the destination swara.
double? stablePitch(List<double> frequencies, {bool glidingToTarget = false}) {
  if (frequencies.isEmpty) return null;
  final followsGlide =
      glidingToTarget || _containsDirectionalGlide(frequencies);
  final List<double> settled;
  if (followsGlide && frequencies.length >= 4) {
    // The ending samples represent the destination, not the midpoint of travel.
    final tailCount = math.max(3, (frequencies.length / 4).ceil());
    settled = frequencies.sublist(frequencies.length - tailCount);
  } else if (frequencies.length >= 3) {
    settled = frequencies.sublist(frequencies.length ~/ 3);
  } else {
    settled = List.of(frequencies);
  }
  return _medianFrequency(settled);
}

bool _containsDirectionalGlide(List<double> frequencies) {
  if (frequencies.length < 5) return false;

  // Compare edge medians so isolated detector jumps do not look like a glide.
  final edgeCount = math.max(2, (frequencies.length / 4).ceil());
  final initial = _medianFrequency(frequencies.take(edgeCount).toList());
  final terminal = _medianFrequency(
    frequencies.skip(frequencies.length - edgeCount).toList(),
  );
  final drift = centsForRatio(terminal / initial);
  if (drift.abs() < 35) return false;

  // Require consistent movement as well as net drift to reject small vibrato.
  final direction = drift > 0 ? 1 : -1;
  var meaningfulSteps = 0;
  var matchingSteps = 0;
  for (var i = 1; i < frequencies.length; i++) {
    final delta = centsForRatio(frequencies[i] / frequencies[i - 1]);
    if (delta.abs() < 4) continue;
    meaningfulSteps++;
    if ((delta > 0 ? 1 : -1) == direction) matchingSteps++;
  }

  final minimumSteps = math.max(2, ((frequencies.length - 1) / 3).ceil());
  return meaningfulSteps >= minimumSteps &&
      matchingSteps / meaningfulSteps >= 0.65;
}

double _medianFrequency(List<double> frequencies) {
  frequencies.sort();
  final middle = frequencies.length ~/ 2;
  // The geometric mean is the midpoint on the logarithmic pitch scale.
  return frequencies.length.isOdd
      ? frequencies[middle]
      : math.sqrt(frequencies[middle - 1] * frequencies[middle]);
}
