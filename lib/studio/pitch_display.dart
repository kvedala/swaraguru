import '../models/pitch_evaluation.dart';
import '../models/swara.dart';

/// Where the live pitch readout's current value came from.
enum PitchDisplaySource { idle, reference, voice }

/// Immutable readout state for a reference note, a detected note, or no pitch.
///
/// Display state is separate from step evaluations so settling the visible
/// note does not delay lesson grading.
class PitchDisplay {
  const PitchDisplay({
    required this.label,
    required this.title,
    this.frequencyHz = 0,
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
    inRaga: swara.inRaga,
    source: PitchDisplaySource.voice,
  );

  static const idle = PitchDisplay(label: '—', title: 'Ready to Listen');

  static const listening = PitchDisplay(
    label: '…',
    title: 'Waiting for a steady note…',
  );

  final String label;
  final String title;
  final double frequencyHz;
  final bool inRaga;
  final PitchDisplaySource source;

  bool get hasPitch => frequencyHz > 0;
}
