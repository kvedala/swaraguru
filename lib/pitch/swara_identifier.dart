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
    // On a logarithmic scale, octave jumps add a constant 1200. Use the
    // equal-tempered position as a starting point, then compare actual ratios.
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

/// Robust pitch for one sung step: discards the attack (first third of the
/// readings) and returns the median of the remainder.
double? stablePitch(List<double> frequencies) {
  if (frequencies.isEmpty) return null;
  final settled = frequencies.length >= 3
      ? frequencies.sublist(frequencies.length ~/ 3)
      : List.of(frequencies);
  settled.sort();
  final middle = settled.length ~/ 2;
  // The geometric mean is the midpoint on the logarithmic pitch scale.
  return settled.length.isOdd
      ? settled[middle]
      : math.sqrt(settled[middle - 1] * settled[middle]);
}
