import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
import 'live_pitch_readout.dart';

/// Live swara readout plus matched / apasruti / wrong-swara counters.
class EvaluationSummaryBanner extends StatelessWidget {
  const EvaluationSummaryBanner({
    super.key,
    required this.controller,
    this.showPitch = true,
  });

  final StudioController controller;
  final bool showPitch;

  @override
  Widget build(BuildContext context) {
    final evaluations = controller.evaluations.values;
    final total = evaluations.length;
    int count(NoteMatchStatus status) =>
        evaluations.where((e) => e.status == status).length;
    final noVoice = count(NoteMatchStatus.noVoice);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            if (showPitch) LivePitchReadout(display: controller.pitchDisplay),
            if (total > 0)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountChip(
                    color: SwaraColors.emeraldMatch,
                    label: 'Matched: ${count(NoteMatchStatus.match)}/$total',
                  ),
                  _CountChip(
                    color: SwaraColors.warmAmber,
                    label: 'Pitch drift: ${count(NoteMatchStatus.apasruti)}',
                  ),
                  _CountChip(
                    color: SwaraColors.crimsonRobes,
                    label: 'Wrong Swara: ${count(NoteMatchStatus.wrongSwara)}',
                  ),
                  if (noVoice > 0)
                    _CountChip(
                      color: Colors.blueGrey,
                      label: 'No Voice: $noVoice',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.2),
      label: Text(label),
    );
  }
}
