import 'package:material_ui/material_ui.dart';

import '../../studio/studio_controller.dart';
import 'bpm_stepper.dart';
import 'drone_controls.dart';
import 'labels.dart';

class PracticeAudioControls extends StatelessWidget {
  const PracticeAudioControls({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final metronomeOn = controller.metronomeOn;
    final dronePlaying = controller.dronePlaying;
    final volumeLabel = '${(100 * controller.practiceVolume).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ControlLabel('Shared volume: $volumeLabel'),
        Semantics(
          label: 'Shared volume for Shruti and metronome',
          child: Slider(
            value: controller.practiceVolume,
            label: volumeLabel,
            onChanged: controller.setPracticeVolume,
          ),
        ),
        if (controller.canUseMetronome) ...[
          const SectionLabel('Metronome'),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: controller.toggleMetronome,
                icon: Icon(metronomeOn ? Icons.stop : Icons.play_arrow),
                label: Text(metronomeOn ? 'Stop metronome' : 'Start metronome'),
              ),
              BpmStepper(controller: controller),
            ],
          ),
          const Divider(height: 24),
        ],
        const SectionLabel('Shruti box'),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: controller.toggleDrone,
          icon: Icon(dronePlaying ? Icons.stop : Icons.play_arrow),
          label: Text(dronePlaying ? 'Stop Shruti' : 'Play Shruti'),
        ),
        const SizedBox(height: 12),
        DroneControls(controller: controller),
      ],
    );
  }
}
