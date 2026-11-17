import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../studio/pitch_display.dart';
import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
import '../widgets/evaluation_summary.dart';
import '../widgets/labels.dart';
import '../widgets/live_pitch_readout.dart';

/// Live note identification and Sing & Match diagnostics.
class PitchCoachScreen extends StatelessWidget {
  const PitchCoachScreen({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LiveTunerCard(controller: controller),
        const SizedBox(height: 16),
        _CoachingCard(controller: controller),
      ],
    );
  }
}

class _LiveTunerCard extends StatelessWidget {
  const _LiveTunerCard({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final listening = controller.isListening;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Listen & Identify Swara',
              subtitle:
                  'Sing or play any note: SwaraGuru names the nearest '
                  'swarasthana of ${controller.raga.name} relative to Sa '
                  '(${controller.saHz.toStringAsFixed(2)} Hz).',
              trailing: FilledButton.icon(
                onPressed: controller.toggleListening,
                style: FilledButton.styleFrom(
                  backgroundColor: listening
                      ? SwaraColors.crimsonRobes
                      : SwaraColors.emeraldMatch,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  listening ? Icons.hearing_disabled_rounded : Icons.hearing,
                ),
                label: Text(listening ? 'Stop Listening' : 'Listen & Identify'),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<PitchDisplay>(
              valueListenable: controller.pitchDisplay,
              builder: (context, pitch, _) {
                final heard = pitch.source == PitchDisplaySource.voice;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SwaraBadge(
                          label: pitch.label,
                          inRaga: pitch.inRaga,
                          size: 76,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pitch.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pitch.hasPitch
                                    ? '${pitch.frequencyHz.toStringAsFixed(1)} Hz'
                                          '${heard ? ' • ${formatCents(pitch.centsOff)} cents' : ''}'
                                    : listening
                                    ? 'Waiting for a steady pitch…'
                                    : 'Press "Listen & Identify" to use '
                                          'the microphone.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: SwaraColors.cyanWave,
                                ),
                              ),
                              if (heard && !pitch.inRaga)
                                Text(
                                  'Not part of ${controller.raga.name}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SwaraColors.warmAmber,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CentsMeter(centsOff: pitch.centsOff, active: heard),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.headphones_rounded, size: 16, color: Colors.white54),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Use headphones so the drone and reference swaras do not '
                    'leak into the microphone. Audio is analysed on-device '
                    'and never recorded or uploaded.',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
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

class _CoachingCard extends StatelessWidget {
  const _CoachingCard({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final coaching = controller.isCoaching;
    final mistakes = controller.evaluations.values
        .where((e) => e.status != NoteMatchStatus.match)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Real-Time Vocal Pitch Analyzer & Mistake Coach',
              subtitle:
                  'Sing "${controller.activeLesson.title}" with the swara grid '
                  'and get flagged for Apasruti drift or wrong Swarasthanas.',
              trailing: FilledButton.icon(
                onPressed: coaching
                    ? controller.stopTransport
                    : controller.startCoaching,
                style: FilledButton.styleFrom(
                  backgroundColor: coaching
                      ? SwaraColors.crimsonRobes
                      : SwaraColors.emeraldMatch,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(coaching ? Icons.stop : Icons.mic),
                label: Text(coaching ? 'Stop Coaching' : 'Start Sing & Match'),
              ),
            ),
            const SizedBox(height: 12),
            const ControlLabel('Coach Input'),
            const SizedBox(height: 8),
            SegmentedButton<CoachInput>(
              showSelectedIcon: false,
              segments: [
                for (final input in CoachInput.values)
                  ButtonSegment(
                    value: input,
                    label: Text(input.label),
                    icon: Icon(
                      input == CoachInput.microphone
                          ? Icons.mic_rounded
                          : Icons.smart_toy_outlined,
                      size: 18,
                    ),
                  ),
              ],
              selected: {controller.coachInput},
              onSelectionChanged: (selection) =>
                  controller.setCoachInput(selection.first),
            ),
            const SizedBox(height: 6),
            Text(
              controller.coachInput.description,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
            const Divider(color: SwaraColors.borderGold, height: 24),
            EvaluationSummaryBanner(controller: controller),
            const SizedBox(height: 14),
            const SectionLabel('IDENTIFIED SWARASTHANA & APASRUTI MISTAKES'),
            const SizedBox(height: 8),
            if (mistakes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No mistakes logged yet. Press "Start Sing & Match" to '
                  'evaluate your singing against the active Varisai.',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
              )
            else
              for (final mistake in mistakes) _MistakeTile(mistake: mistake),
          ],
        ),
      ),
    );
  }
}

class _MistakeTile extends StatelessWidget {
  const _MistakeTile({required this.mistake});

  final StepPitchEvaluation mistake;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (mistake.status) {
      NoteMatchStatus.wrongSwara => (
        Icons.cancel_rounded,
        SwaraColors.crimsonRobes,
      ),
      NoteMatchStatus.noVoice => (Icons.mic_off_rounded, Colors.blueGrey),
      _ => (Icons.warning_amber_rounded, SwaraColors.warmAmber),
    };
    final sung = mistake.sung;
    final sungHz = mistake.sungFreqHz;
    final heard = sung == null || sungHz == null
        ? 'No voice'
        : 'Sung ${sung.label} (${sungHz.toStringAsFixed(1)} Hz)';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      leading: Icon(icon, color: color),
      title: Text(
        'Step #${mistake.stepIndex + 1}: Expected ${mistake.expected.label} '
        '(${mistake.expectedFreqHz.toStringAsFixed(1)} Hz) • $heard',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        mistake.message,
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}
