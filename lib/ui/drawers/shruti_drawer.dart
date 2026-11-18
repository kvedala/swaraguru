import 'package:material_ui/material_ui.dart';

import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
import '../widgets/practice_audio_controls.dart';

class PracticeAudioDrawer extends StatelessWidget {
  const PracticeAudioDrawer({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 360,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Practice audio',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SwaraColors.brightGold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: PracticeAudioControls(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
