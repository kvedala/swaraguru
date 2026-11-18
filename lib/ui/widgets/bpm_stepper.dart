import 'package:material_ui/material_ui.dart';

import '../../studio/studio_controller.dart';

class BpmStepper extends StatelessWidget {
  const BpmStepper({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final bpm = controller.bpm;
    const increment = StudioController.bpmIncrement;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease tempo by $increment BPM',
          onPressed: bpm > StudioController.minBpm
              ? () => controller.setBpm(bpm - increment)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$bpm BPM', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          tooltip: 'Increase tempo by $increment BPM',
          onPressed: bpm < StudioController.maxBpm
              ? () => controller.setBpm(bpm + increment)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
