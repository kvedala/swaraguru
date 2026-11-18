import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
import '../widgets/bpm_stepper.dart';
import '../widgets/evaluation_summary.dart';
import '../widgets/instrument_selector.dart';
import '../widgets/labels.dart';
import '../widgets/raga_selector.dart';
import '../widgets/swara_grid.dart';

/// Base Sa, kaalam, raga and instrument selection plus the Adi tala swara
/// grid for the active lesson.
class VarisaiStudioScreen extends StatelessWidget {
  const VarisaiStudioScreen({
    super.key,
    required this.controller,
    required this.onAddCustomLesson,
  });

  final StudioController controller;
  final VoidCallback onAddCustomLesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RagaAndInstrumentCard(controller: controller),
        const SizedBox(height: 16),
        _LessonGridCard(
          controller: controller,
          onAddCustomLesson: onAddCustomLesson,
        ),
        if (controller.isTransportRunning ||
            controller.activeStepIndex >= 0 ||
            controller.evaluations.isNotEmpty) ...[
          const SizedBox(height: 16),
          EvaluationSummaryBanner(controller: controller),
        ],
      ],
    );
  }
}

class _TempoControls extends StatelessWidget {
  const _TempoControls({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        BpmStepper(controller: controller),
        PopupMenuButton<KaalamSpeed>(
          tooltip: 'Select kaalam (swaras per beat)',
          initialValue: controller.kaalam,
          onSelected: controller.selectKaalam,
          itemBuilder: (_) => [
            for (final speed in kKaalamOptions)
              PopupMenuItem(
                value: speed,
                child: Text(
                  'Kaalam ${speed.kaalam}: ${speed.swarasPerBeat} swaras/beat',
                ),
              ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kaalam ${controller.kaalam.kaalam}'),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ],
    );
  }
}

class _RagaAndInstrumentCard extends StatelessWidget {
  const _RagaAndInstrumentCard({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('Practice settings'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RagaSelector(
                      ragas: controller.catalog.sortedRagas,
                      selected: controller.raga,
                      width: constraints.maxWidth < 340
                          ? constraints.maxWidth
                          : 320,
                      onSelected: controller.selectRaga,
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.practiceRagaScale,
                      icon: const Icon(Icons.stairs_rounded, size: 18),
                      label: const Text('Practice Raga Scale'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RagaScaleSummary(raga: controller.raga),
                const SizedBox(height: 16),
                const ControlLabel('Playback instrument'),
                const SizedBox(height: 8),
                InstrumentSelector(
                  selected: controller.noteInstrument,
                  onChanged: controller.setNoteInstrument,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonGridCard extends StatelessWidget {
  const _LessonGridCard({
    required this.controller,
    required this.onAddCustomLesson,
  });

  final StudioController controller;
  final VoidCallback onAddCustomLesson;

  @override
  Widget build(BuildContext context) {
    final lesson = controller.activeLesson;
    final raga = controller.raga;
    final retuned =
        controller.catalog.ragaNamed(lesson.raga)?.name != raga.name;
    final running = controller.isTransportRunning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: SwaraColors.brightGold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${raga.name} • ${lesson.tala}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!running) ...[
                      FilledButton.icon(
                        onPressed: controller.playReference,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Play Varisai'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: controller.startCoaching,
                        style: FilledButton.styleFrom(
                          backgroundColor: SwaraColors.crimsonRobes,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.mic_rounded, size: 18),
                        label: const Text('Sing & Match Swaras'),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: controller.stopTransport,
                        style: FilledButton.styleFrom(
                          backgroundColor: SwaraColors.crimsonRobes,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('Stop Transport'),
                      ),
                    OutlinedButton.icon(
                      onPressed: onAddCustomLesson,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Custom Song'),
                    ),
                  ],
                ),
              ],
            ),
            if (retuned) ...[
              const SizedBox(height: 8),
              Text(
                'Composed in ${lesson.raga}; unnumbered swaras now follow '
                '${raga.name}.',
                style: const TextStyle(
                  fontSize: 11,
                  color: SwaraColors.warmAmber,
                ),
              ),
            ],
            if (controller.coachInput != CoachInput.microphone)
              Text('Coach input: ${controller.coachInput.label}'),
            const SizedBox(height: 8),
            _TempoControls(controller: controller),
            const SizedBox(height: 14),
            AdiTalaBeatStrip(
              activeBeat: running ? controller.activeBeat : null,
            ),
            const SizedBox(height: 16),
            SwaraGrid(
              steps: controller.steps,
              saHz: controller.saHz,
              activeStepIndex: controller.activeStepIndex,
              evaluations: controller.evaluations,
              onTapStep: controller.previewStep,
            ),
          ],
        ),
      ),
    );
  }
}
