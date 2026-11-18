import 'package:material_ui/material_ui.dart';

import '../audio/swara_audio.dart';
import '../models/models.dart';
import '../pitch/pitch_source.dart';
import '../studio/studio_controller.dart';
import '../theme/swara_theme.dart';
import 'dialogs/custom_lesson_dialog.dart';
import 'drawers/navigation_drawer.dart';
import 'drawers/shruti_drawer.dart';
import 'screens/drone_lab_screen.dart';
import 'screens/info_pages.dart';
import 'screens/pitch_coach_screen.dart';
import 'screens/varisai_studio_screen.dart';
import 'widgets/hero_banner.dart';
import 'widgets/logo_emblem.dart';
import 'widgets/version_badge.dart';

/// Responsive shell: bottom navigation on phones, a navigation rail on
/// tablets and an extended rail on desktops.
class SwaraGuruAdaptiveScaffold extends StatefulWidget {
  const SwaraGuruAdaptiveScaffold({
    super.key,
    required this.catalog,
    this.audio,
    this.pitchSource,
  });

  final CarnaticCatalog catalog;

  /// Overrides the platform instrument engine (used by tests).
  final SwaraAudio? audio;

  /// Overrides the microphone pitch source (used by tests).
  final PitchSource? pitchSource;

  @override
  State<SwaraGuruAdaptiveScaffold> createState() =>
      _SwaraGuruAdaptiveScaffoldState();
}

class _SwaraGuruAdaptiveScaffoldState extends State<SwaraGuruAdaptiveScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final StudioController _controller;
  late Future<String> _readme;

  StudioScreen _screen = StudioScreen.varisai;
  InfoPage? _infoPage;

  @override
  void initState() {
    super.initState();
    _controller = StudioController(
      catalog: widget.catalog,
      audio: widget.audio,
      pitchSource: widget.pitchSource,
    )..onNotice = _showNotice;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readme = DefaultAssetBundle.of(context).loadString('README.md');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _title => _infoPage?.title ?? _screen.title;

  void _selectScreen(StudioScreen screen) {
    setState(() {
      _screen = screen;
      _infoPage = null;
    });
  }

  void _openInfoPage(InfoPage page) => setState(() => _infoPage = page);

  void _selectLesson(CarnaticLesson lesson) {
    _controller.selectLesson(lesson);
    _selectScreen(StudioScreen.varisai);
  }

  void _addCustomLesson() => showCustomLessonDialog(context, _controller);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          final isMobile = constraints.maxWidth < 600;
          return Scaffold(
            key: _scaffoldKey,
            appBar: _StudioAppBar(
              controller: _controller,
              title: _title,
              isMobile: isMobile,
              onHome: () => _selectScreen(StudioScreen.varisai),
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onOpenEndDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            drawer: SwaraGuruNavigationDrawer(
              screen: _screen,
              infoPage: _infoPage,
              lessons: _controller.lessons,
              activeLesson: _controller.activeLesson,
              onSelectScreen: _selectScreen,
              onOpenInfoPage: _openInfoPage,
              onSelectLesson: _selectLesson,
              onAddCustomLesson: _addCustomLesson,
            ),
            endDrawer: ShrutiDrawer(controller: _controller),
            body: Row(
              children: [
                if (!isMobile) ...[
                  NavigationRail(
                    backgroundColor: SwaraColors.indigoSurface,
                    selectedIndex: _infoPage == null ? _screen.index : null,
                    extended: isDesktop,
                    onDestinationSelected: (index) =>
                        _selectScreen(StudioScreen.values[index]),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: SwaraGuruLogoEmblem(size: isDesktop ? 48 : 38),
                    ),
                    destinations: [
                      for (final screen in StudioScreen.values)
                        NavigationRailDestination(
                          icon: Icon(screen.icon),
                          label: Text(screen.title),
                        ),
                    ],
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: SwaraColors.borderGold,
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(_infoPage?.name ?? 'screen-${_screen.name}'),
                    padding: const EdgeInsets.all(16),
                    child: _buildPage(),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: isMobile && _infoPage == null
                ? NavigationBar(
                    backgroundColor: SwaraColors.indigoSurface,
                    selectedIndex: _screen.index,
                    onDestinationSelected: (index) =>
                        _selectScreen(StudioScreen.values[index]),
                    destinations: [
                      for (final screen in StudioScreen.values)
                        NavigationDestination(
                          icon: Icon(screen.icon),
                          label: screen.shortTitle,
                        ),
                    ],
                  )
                : null,
            floatingActionButton: const WebVersionBadge(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  Widget _buildPage() {
    final infoPage = _infoPage;
    if (infoPage != null) {
      return InfoPageView(page: infoPage, readme: _readme);
    }
    final controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwaraGuruHeroBanner(
          activeShruti: controller.shruti,
          saHz: controller.saHz,
          raga: controller.raga,
          dronePlaying: controller.dronePlaying,
          droneSummary: controller.drone.summary,
          onToggleDrone: controller.toggleDrone,
          onOpenShrutiDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        const SizedBox(height: 16),
        switch (_screen) {
          StudioScreen.varisai => VarisaiStudioScreen(
            controller: controller,
            onAddCustomLesson: _addCustomLesson,
          ),
          StudioScreen.pitchCoach => PitchCoachScreen(controller: controller),
          StudioScreen.droneLab => DroneLabScreen(controller: controller),
        },
      ],
    );
  }
}

class _StudioAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StudioAppBar({
    required this.controller,
    required this.title,
    required this.isMobile,
    required this.onHome,
    required this.onOpenDrawer,
    required this.onOpenEndDrawer,
  });

  final StudioController controller;
  final String title;
  final bool isMobile;
  final VoidCallback onHome;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenEndDrawer;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final dronePlaying = controller.dronePlaying;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Open Navigation & Varisai Drawer',
        onPressed: onOpenDrawer,
      ),
      title: Row(
        children: [
          if (!isMobile) ...[
            const SwaraGuruLogoEmblem(size: 32),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SwaraGuru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: SwaraColors.brightGold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Home (Varisai Studio)',
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded),
        ),
        PopupMenuButton<ShrutiPitch>(
          tooltip: 'Select Base Sa (Adhara Shadjam)',
          initialValue: controller.shruti,
          onSelected: controller.selectShruti,
          itemBuilder: (_) => [
            for (final shruti in kShrutiPitches)
              PopupMenuItem(
                value: shruti,
                child: Text(
                  'Sa = ${shruti.label} • ${shruti.kattaiName} '
                  '(${shruti.frequencyHz.toStringAsFixed(2)} Hz)',
                ),
              ),
          ],
          child: _AppBarPill(
            icon: Icons.music_note,
            iconColor: SwaraColors.royalGold,
            label: 'Sa: ${controller.shruti.label}',
          ),
        ),
        const SizedBox(width: 8),
        if (!isMobile) ...[
          PopupMenuButton<KaalamSpeed>(
            tooltip: 'Select Kaalam Tempo (1, 2, 3, 4)',
            initialValue: controller.kaalam,
            onSelected: controller.selectKaalam,
            itemBuilder: (_) => [
              for (final kaalam in kKaalamOptions)
                PopupMenuItem(
                  value: kaalam,
                  child: Text(
                    '${kaalam.name} (${kaalam.swarasPerBeat} Swaras/Beat)',
                  ),
                ),
            ],
            child: _AppBarPill(
              icon: Icons.speed,
              iconColor: SwaraColors.cyanWave,
              label:
                  'Tempo ${controller.kaalam.kaalam} '
                  '(${controller.kaalam.swarasPerBeat}x)',
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          tooltip: 'Open Shruti Box EndDrawer',
          onPressed: onOpenEndDrawer,
          icon: Icon(
            dronePlaying ? Icons.volume_up_rounded : Icons.tune_rounded,
            color: dronePlaying ? SwaraColors.royalGold : Colors.white70,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _AppBarPill extends StatelessWidget {
  const _AppBarPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SwaraColors.midnightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SwaraColors.borderGold),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }
}
