import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
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
        _SaAndTempoCard(controller: controller),
        const SizedBox(height: 16),
        _RagaAndInstrumentCard(controller: controller),
        const SizedBox(height: 16),
        _LessonGridCard(
          controller: controller,
          onAddCustomLesson: onAddCustomLesson,
        ),
        const SizedBox(height: 16),
        EvaluationSummaryBanner(controller: controller),
      ],
    );
  }
}

class _SaAndTempoCard extends StatelessWidget {
  const _SaAndTempoCard({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(
              'SELECT BASE "SA" (A, A#, B, C, C# … G#) & TEMPO (KAALAM 1–4)',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final shruti in kShrutiPitches)
                  _ShrutiChip(
                    shruti: shruti,
                    selected: shruti == controller.shruti,
                    onSelected: () => controller.selectShruti(shruti),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final kaalam in kKaalamOptions)
                  _KaalamChip(
                    kaalam: kaalam,
                    selected: kaalam.kaalam == controller.kaalam.kaalam,
                    onSelected: () => controller.selectKaalam(kaalam),
                  ),
                const SizedBox(width: 12),
                Text(
                  'Laya BPM: ${controller.bpm}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: SwaraColors.brightGold,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: controller.bpm.toDouble(),
                    min: 40,
                    max: 140,
                    divisions: 100,
                    label: '${controller.bpm} BPM',
                    onChanged: (value) => controller.setBpm(value.round()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShrutiChip extends StatelessWidget {
  const _ShrutiChip({
    required this.shruti,
    required this.selected,
    required this.onSelected,
  });

  final ShrutiPitch shruti;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      tooltip: '${shruti.kattaiName} • ${shruti.frequencyHz} Hz',
      label: Text(
        '${shruti.label} • ${shruti.kattaiName} '
        '(${shruti.frequencyHz.toStringAsFixed(2)} Hz)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: selected ? SwaraColors.midnightBg : Colors.white,
        ),
      ),
      selected: selected,
      selectedColor: SwaraColors.royalGold,
      backgroundColor: SwaraColors.midnightBg,
      onSelected: (_) => onSelected(),
    );
  }
}

class _KaalamChip extends StatelessWidget {
  const _KaalamChip({
    required this.kaalam,
    required this.selected,
    required this.onSelected,
  });

  final KaalamSpeed kaalam;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        'Tempo ${kaalam.kaalam} • ${kaalam.sanskritName} '
        '(${kaalam.swarasPerBeat}x)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: selected ? SwaraColors.midnightBg : SwaraColors.cyanWave,
        ),
      ),
      selected: selected,
      selectedColor: SwaraColors.cyanWave,
      backgroundColor: SwaraColors.midnightBg,
      onSelected: (_) => onSelected(),
    );
  }
}

class _RagaAndInstrumentCard extends StatelessWidget {
  const _RagaAndInstrumentCard({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('SESSION RAGA & VARISAI INSTRUMENT'),
              const SizedBox(height: 12),
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
              const ControlLabel('Varisai Playback Instrument'),
              const SizedBox(height: 8),
              InstrumentSelector(
                selected: controller.noteInstrument,
                onChanged: controller.setNoteInstrument,
              ),
            ],
          ),
        ),
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
                      'Raga: ${raga.name} • ${lesson.tala} • '
                      '${controller.kaalam.name}',
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
            const SizedBox(height: 6),
            Text(
              'Sing & Match listens with: ${controller.coachInput.label} '
              '(change it in Live Pitch Coach)',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
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
