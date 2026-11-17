import 'dart:math' as math;

import '../models/pitch_evaluation.dart';
import '../models/raga.dart';
import '../models/swara.dart';

/// Deviation in cents tolerated before a swara is marked apasruti.
const double kApasrutiToleranceCents = 25;

/// Names detected frequencies as swarasthanas relative to the current Sa.
class SwaraIdentifier {
  const SwaraIdentifier({required this.saHz, required this.scale});

  final double saHz;
  final RagaScale scale;

  /// Finds the nearest swarasthana to [frequencyHz] in any octave.
  IdentifiedSwara identify(double frequencyHz) {
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
    final cents = heard.centsOff.round();
    final samePosition = heard.note.swara.position == expected.swara.position;

    final (status, message) = !samePosition
        ? (
            NoteMatchStatus.wrongSwara,
            'Sang ${heard.note.label} (${heard.note.fullName}) instead of '
                '${expected.label}',
          )
        : cents.abs() > kApasrutiToleranceCents
        ? (
            NoteMatchStatus.apasruti,
            'Apasruti: ${cents > 0 ? '+$cents' : '$cents'} cents drift on '
                '${expected.label}',
          )
        : (NoteMatchStatus.match, 'Sruti Suddham (Exact Swarasthana)');

    return StepPitchEvaluation(
      stepIndex: stepIndex,
      expected: expected,
      expectedFreqHz: expectedHz,
      sung: samePosition
          ? SwaraNote(expected.swara, heard.note.octave)
          : heard.note,
      sungFreqHz: sungFrequencyHz,
      centDeviation: cents,
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
  return settled.length.isOdd
      ? settled[middle]
      : math.sqrt(settled[middle - 1] * settled[middle]);
}
