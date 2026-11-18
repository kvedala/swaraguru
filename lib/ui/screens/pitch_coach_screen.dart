import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../pitch/swara_identifier.dart';
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
              subtitle: 'Hold a note to see the nearest swara relative to Sa.',
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
                if (!heard || !listening) {
                  return Text(
                    listening ? PitchDisplay.listening.title : 'Microphone off',
                  );
                }
                return Row(
                  children: [
                    SwaraBadge(label: pitch.label, inRaga: pitch.inRaga),
                    const SizedBox(width: 12),
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
                          Text('${pitch.frequencyHz.toStringAsFixed(1)} Hz'),
                          if (!pitch.inRaga)
                            Text('Not part of ${controller.raga.name}'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('How note detection works'),
              children: [
                Text(
                  'The microphone listens for how fast your voice vibrates. '
                  'The app compares that pitch with the swaras above and below '
                  'your chosen Sa. It waits for about a quarter second of '
                  'consistent readings before showing a note, so brief slides '
                  'do not immediately change the label. Use headphones so the '
                  'mic does not pick up the drone. Audio stays on your device.',
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
              title: 'Sing & Match',
              subtitle: 'Practice ${controller.activeLesson.title}.',
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
            DropdownButton<CoachInput>(
              value: controller.coachInput,
              items: [
                for (final input in CoachInput.values)
                  DropdownMenuItem(value: input, child: Text(input.label)),
              ],
              onChanged: (input) {
                if (input != null) controller.setCoachInput(input);
              },
            ),
            ControlLabel(
              'Pitch tolerance: ${controller.pitchTolerancePercent.toStringAsFixed(1)}%',
            ),
            Semantics(
              label: 'Pitch matching tolerance',
              child: Slider(
                value: controller.pitchTolerancePercent,
                max: SwaraIdentifier.maxTolerancePercent,
                divisions: 30,
                label:
                    '${controller.pitchTolerancePercent.toStringAsFixed(1)}%',
                onChanged: controller.setPitchTolerancePercent,
              ),
            ),
            const Text(
              'Allowed difference above or below the target. Applies to new notes.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            if (controller.evaluations.isNotEmpty)
              EvaluationSummaryBanner(controller: controller, showPitch: false),
            if (mistakes.isNotEmpty)
              ExpansionTile(
                title: Text('Notes to review (${mistakes.length})'),
                children: [
                  for (final mistake in mistakes)
                    _MistakeTile(mistake: mistake),
                ],
              ),
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
