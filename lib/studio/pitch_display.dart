import '../models/pitch_evaluation.dart';
import '../models/swara.dart';

/// Where the live pitch readout's current value came from.
enum PitchDisplaySource { idle, reference, voice }

/// Snapshot shown by the live swara readout and tuner.
class PitchDisplay {
  const PitchDisplay({
    required this.label,
    required this.title,
    this.frequencyHz = 0,
    this.centsOff = 0,
    this.inRaga = true,
    this.source = PitchDisplaySource.idle,
  });

  factory PitchDisplay.reference(SwaraNote note, double frequencyHz) =>
      PitchDisplay(
        label: note.label,
        title: note.fullName,
        frequencyHz: frequencyHz,
        source: PitchDisplaySource.reference,
      );

  factory PitchDisplay.heard(IdentifiedSwara swara) => PitchDisplay(
    label: swara.note.label,
    title: swara.note.fullName,
    frequencyHz: swara.frequencyHz,
    centsOff: swara.centsOff,
    inRaga: swara.inRaga,
    source: PitchDisplaySource.voice,
  );

  static const idle = PitchDisplay(label: '—', title: 'Ready to Listen');

  static const listening = PitchDisplay(
    label: '…',
    title: 'Listening — sing or play a steady swara',
  );

  final String label;
  final String title;
  final double frequencyHz;
  final double centsOff;
  final bool inRaga;
  final PitchDisplaySource source;

  bool get hasPitch => frequencyHz > 0;
}
