import 'package:material_ui/material_ui.dart';

import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
import '../widgets/drone_controls.dart';

/// Right drawer with the shruti box mixer.
class ShrutiDrawer extends StatelessWidget {
  const ShrutiDrawer({super.key, required this.controller});

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
                      'Shruti Drone Mixer',
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
                const Text(
                  'Choose between a Pure Single Note reference or a '
                  'Multi-Note Tambura chord.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: DroneControls(controller: controller),
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
