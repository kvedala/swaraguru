import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../theme/swara_theme.dart';
import '../screens/info_pages.dart';
import '../widgets/labels.dart';
import '../widgets/logo_emblem.dart';

/// The three main studio screens.
enum StudioScreen { varisai, pitchCoach, droneLab }

extension StudioScreenInfo on StudioScreen {
  String get title => switch (this) {
    StudioScreen.varisai => 'Varisai Studio',
    StudioScreen.pitchCoach => 'Live Pitch Coach',
    StudioScreen.droneLab => 'Practice Audio',
  };

  String get drawerTitle => switch (this) {
    StudioScreen.varisai => 'Varisai Studio (Adi Tala Grid)',
    StudioScreen.pitchCoach => 'Live Vocal Pitch Coach',
    StudioScreen.droneLab => 'Practice Audio',
  };

  String get shortTitle => switch (this) {
    StudioScreen.varisai => 'Studio',
    StudioScreen.pitchCoach => 'Pitch Coach',
    StudioScreen.droneLab => 'Audio',
  };

  IconData get icon => switch (this) {
    StudioScreen.varisai => Icons.grid_view_rounded,
    StudioScreen.pitchCoach => Icons.mic_external_on_rounded,
    StudioScreen.droneLab => Icons.surround_sound_rounded,
  };
}

/// Left drawer: screens, help & legal pages and the lesson repertoire.
/// Every action closes the drawer before invoking its callback.
class SwaraGuruNavigationDrawer extends StatelessWidget {
  const SwaraGuruNavigationDrawer({
    super.key,
    required this.screen,
    required this.infoPage,
    required this.lessons,
    required this.activeLesson,
    required this.onSelectScreen,
    required this.onOpenInfoPage,
    required this.onSelectLesson,
    required this.onAddCustomLesson,
  });

  final StudioScreen screen;
  final InfoPage? infoPage;
  final List<CarnaticLesson> lessons;
  final CarnaticLesson activeLesson;
  final ValueChanged<StudioScreen> onSelectScreen;
  final ValueChanged<InfoPage> onOpenInfoPage;
  final ValueChanged<CarnaticLesson> onSelectLesson;
  final VoidCallback onAddCustomLesson;

  @override
  Widget build(BuildContext context) {
    void closeThen(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return Drawer(
      width: 320,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _DrawerHeader(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SectionLabel('APP SCREENS'),
            ),
            for (final item in StudioScreen.values)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.drawerTitle),
                selected: infoPage == null && screen == item,
                onTap: () => closeThen(() => onSelectScreen(item)),
              ),
            const Divider(color: SwaraColors.borderGold),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SectionLabel('HELP & LEGAL'),
            ),
            for (final (page, icon) in const [
              (InfoPage.help, Icons.help_outline_rounded),
              (InfoPage.privacy, Icons.privacy_tip_outlined),
              (InfoPage.license, Icons.description_outlined),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(page.title),
                selected: infoPage == page,
                onTap: () => closeThen(() => onOpenInfoPage(page)),
              ),
            const Divider(color: SwaraColors.borderGold),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionLabel('REPERTOIRE'),
                  TextButton.icon(
                    onPressed: () => closeThen(onAddCustomLesson),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Custom', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            for (final lesson in lessons)
              ListTile(
                selected: lesson.id == activeLesson.id,
                selectedTileColor: SwaraColors.royalGold.withValues(
                  alpha: 0.15,
                ),
                title: Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${lesson.group} • ${lesson.raga} • '
                  '${lesson.swaras.length} Swaras',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
                onTap: () => closeThen(() => onSelectLesson(lesson)),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SwaraColors.borderGold)),
      ),
      child: const Row(
        children: [
          SwaraGuruLogoEmblem(size: 46),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SwaraGuru Studio',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SwaraColors.brightGold,
                  ),
                ),
                Text(
                  'Screens & Varisai Library',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
