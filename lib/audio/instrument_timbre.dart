import 'dart:math' as math;

import '../models/instrument.dart';

/// Harmonic weights and time constants for a synthesized instrument voice.
///
/// The oscillator supplies the waveform; the gain envelope and low-pass filter
/// shape how loud and bright it sounds over the life of a note.
class InstrumentTimbre {
  const InstrumentTimbre({
    required this.harmonics,
    required this.attackSeconds,
    required this.releaseSeconds,
    required this.filterStartHz,
    required this.filterEndHz,
    required this.filterSweepSeconds,
    required this.peakGain,
    this.decaySeconds,
    this.detuneCents = 0,
  });

  /// Relative amplitude of each harmonic; index 0 is the fundamental.
  final List<double> harmonics;
  final double attackSeconds;
  final double releaseSeconds;

  /// Exponential decay time constant; `null` for a sustained tone.
  final double? decaySeconds;

  /// Low-pass cutoff at the attack, gliding to [filterEndHz].
  final double filterStartHz;
  final double filterEndHz;
  final double filterSweepSeconds;
  final double peakGain;

  /// Detune of a second, beating oscillator (0 for a single oscillator).
  final double detuneCents;

  bool get isPlucked => decaySeconds != null;

  /// Time after the attack at which a plucked tone becomes inaudible.
  double get ringSeconds =>
      attackSeconds + (decaySeconds ?? releaseSeconds) * 5;
}

/// Maps an instrument selection to its synthesis parameters.
extension InstrumentTimbreOf on SwaraInstrument {
  InstrumentTimbre get timbre => switch (this) {
    SwaraInstrument.tampura => _tampura,
    SwaraInstrument.harmonium => _harmonium,
    SwaraInstrument.piano => _piano,
  };
}

// The jawari bridge emphasises a broad band of upper partials around the
// eighth harmonic, giving the tampura its shimmering buzz.
final InstrumentTimbre _tampura = InstrumentTimbre(
  harmonics: [
    for (var n = 1; n <= 24; n++)
      (1 / math.pow(n, 0.85)) * (1 + 1.2 * math.exp(-math.pow(n - 8, 2) / 20)),
  ],
  attackSeconds: 0.004,
  releaseSeconds: 0.25,
  decaySeconds: 1.6,
  filterStartHz: 5000,
  filterEndHz: 1200,
  filterSweepSeconds: 0.9,
  peakGain: 0.55,
);

// Free reeds produce strong odd harmonics; a second reed tuned a few cents
// sharp gives the characteristic harmonium beating.
final InstrumentTimbre _harmonium = InstrumentTimbre(
  harmonics: [for (var n = 1; n <= 14; n++) (n.isOdd ? 1.0 : 0.55) / n],
  attackSeconds: 0.05,
  releaseSeconds: 0.12,
  filterStartHz: 2800,
  filterEndHz: 2800,
  filterSweepSeconds: 1,
  peakGain: 0.32,
  detuneCents: 4,
);

final InstrumentTimbre _piano = InstrumentTimbre(
  harmonics: [for (var n = 1; n <= 16; n++) 1 / math.pow(n, 1.6)],
  attackSeconds: 0.003,
  releaseSeconds: 0.18,
  decaySeconds: 0.9,
  filterStartHz: 6000,
  filterEndHz: 900,
  filterSweepSeconds: 0.5,
  peakGain: 0.6,
);
