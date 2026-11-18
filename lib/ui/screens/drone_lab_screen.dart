import 'package:material_ui/material_ui.dart';

import '../../studio/studio_controller.dart';
import '../widgets/practice_audio_controls.dart';

class PracticeAudioScreen extends StatelessWidget {
  const PracticeAudioScreen({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PracticeAudioControls(controller: controller),
      ),
    );
  }
}
