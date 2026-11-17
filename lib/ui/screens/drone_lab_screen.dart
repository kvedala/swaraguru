import 'package:material_ui/material_ui.dart';

import '../../studio/studio_controller.dart';
import '../widgets/drone_controls.dart';
import '../widgets/labels.dart';

/// Standalone shruti box: tampura, harmonium or piano drone.
class DroneLabScreen extends StatelessWidget {
  const DroneLabScreen({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final playing = controller.dronePlaying;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Shruti Box & Tambura Drone Synthesizer Lab',
              subtitle:
                  'Select a Pure Single-Note reference or mix Multiple '
                  'Tambura Swaras, rendered on tampura, harmonium or piano.',
              trailing: FilledButton.icon(
                onPressed: controller.toggleDrone,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(playing ? 'Stop Drone' : 'Start Drone'),
              ),
            ),
            const SizedBox(height: 16),
            DroneControls(controller: controller),
          ],
        ),
      ),
    );
  }
}
