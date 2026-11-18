import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../theme/swara_theme.dart';

/// Adi tala kriya for each of its eight beats
/// (Laghu of 4 + Dhrutam of 2 + Dhrutam of 2).
String adiTalaKriya(int beat) => switch (beat) {
  1 => 'Clap (Laghu)',
  <= 4 => 'Finger ${beat - 1}',
  _ => beat.isOdd ? 'Clap (Dhrutam)' : 'Wave',
};

class AdiTalaBeatStrip extends StatelessWidget {
  const AdiTalaBeatStrip({super.key, required this.activeBeat});

  /// 1–8, or `null` when the transport is idle.
  final int? activeBeat;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var beat = 1; beat <= 8; beat++)
          _BeatChip(beat: beat, isCurrent: activeBeat == beat),
      ],
    );
  }
}

class _BeatChip extends StatelessWidget {
  const _BeatChip({required this.beat, required this.isCurrent});

  final int beat;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? SwaraColors.royalGold : SwaraColors.midnightBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? SwaraColors.brightGold : SwaraColors.borderGold,
        ),
      ),
      child: Text(
        'Beat $beat • ${adiTalaKriya(beat)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isCurrent ? SwaraColors.midnightBg : Colors.white70,
        ),
      ),
    );
  }
}

/// The lesson's swaras, colour-coded by their pitch evaluation.
class SwaraGrid extends StatelessWidget {
  const SwaraGrid({
    super.key,
    required this.steps,
    required this.saHz,
    required this.activeStepIndex,
    required this.evaluations,
    required this.onTapStep,
  });

  final List<LessonStep> steps;
  final double saHz;
  final int activeStepIndex;
  final Map<int, StepPitchEvaluation> evaluations;
  final ValueChanged<int> onTapStep;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < steps.length; i++)
          SwaraCell(
            step: steps[i],
            saHz: saHz,
            isActive: i == activeStepIndex,
            evaluation: evaluations[i],
            onTap: () => onTapStep(i),
          ),
      ],
    );
  }
}

class SwaraCell extends StatelessWidget {
  const SwaraCell({
    super.key,
    required this.step,
    required this.saHz,
    required this.isActive,
    required this.evaluation,
    required this.onTap,
  });

  final LessonStep step;
  final double saHz;
  final bool isActive;
  final StepPitchEvaluation? evaluation;
  final VoidCallback onTap;

  static const _wrongSwaraText = Color(0xFFFDA4AF);

  @override
  Widget build(BuildContext context) {
    final note = step.note;
    final evaluation = this.evaluation;
    final statusColor = switch (evaluation?.status) {
      NoteMatchStatus.match => SwaraColors.emeraldMatch,
      NoteMatchStatus.apasruti => SwaraColors.warmAmber,
      NoteMatchStatus.wrongSwara => SwaraColors.crimsonRobes,
      NoteMatchStatus.noVoice => Colors.blueGrey,
      null => null,
    };
    final invalid = note == null && !step.isKarvai;
    final borderColor = isActive
        ? SwaraColors.brightGold
        : statusColor ??
              (invalid ? SwaraColors.crimsonRobes : SwaraColors.borderGold);
    final background = isActive
        ? SwaraColors.royalGold.withValues(alpha: 0.25)
        : statusColor?.withValues(alpha: 0.18) ?? SwaraColors.midnightBg;

    final String detail;
    var detailColor = SwaraColors.cyanWave;
    if (evaluation != null) {
      switch (evaluation.status) {
        case NoteMatchStatus.wrongSwara:
          detail = 'Sang ${evaluation.sung?.label ?? '?'}';
          detailColor = _wrongSwaraText;
        case NoteMatchStatus.noVoice:
          detail = 'No voice';
          detailColor = Colors.white54;
        case NoteMatchStatus.match:
          detail = 'Matched';
        case NoteMatchStatus.apasruti:
          detail = evaluation.centDeviation == 0
              ? 'Pitch drift'
              : evaluation.centDeviation > 0
              ? 'Too high'
              : 'Too low';
      }
    } else if (invalid) {
      detail = 'Unknown';
      detailColor = _wrongSwaraText;
    } else if (step.isKarvai) {
      detail = 'Karvai';
    } else {
      detail = '${note!.frequencyFor(saHz).round()} Hz';
    }

    return Tooltip(
      message: switch ((note, step.isKarvai)) {
        (final SwaraNote n, true) => 'Karvai — sustain ${n.fullName}',
        (final SwaraNote n, false) => n.fullName,
        (null, _) => 'Unrecognised swara "${step.token}"',
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isActive ? 2 : 1.2),
          ),
          child: Column(
            children: [
              Text(
                step.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                step.isKarvai ? '—' : note?.telugu ?? '?',
                style: const TextStyle(
                  fontSize: 11,
                  color: SwaraColors.royalGold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: detailColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
