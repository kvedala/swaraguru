import 'package:material_ui/material_ui.dart';

import '../audio/metronome_audio.dart';
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
import 'screens/lesson_library_screen.dart';
import 'screens/pitch_coach_screen.dart';
import 'screens/varisai_studio_screen.dart';
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
    this.metronome,
  });

  final CarnaticCatalog catalog;

  /// Overrides the platform instrument engine (used by tests).
  final SwaraAudio? audio;

  /// Overrides the microphone pitch source (used by tests).
  final PitchSource? pitchSource;
  final MetronomeAudio? metronome;

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
      metronome: widget.metronome,
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

  Future<void> _addCustomLesson() async {
    final added = await showCustomLessonDialog(context, _controller);
    if (added == true && mounted) _selectScreen(StudioScreen.varisai);
  }

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
              onHome: _infoPage != null || _screen != StudioScreen.varisai
                  ? () => _selectScreen(StudioScreen.varisai)
                  : null,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onOpenEndDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            drawer: SwaraGuruNavigationDrawer(
              screen: _screen,
              infoPage: _infoPage,
              onSelectScreen: _selectScreen,
              onOpenInfoPage: _openInfoPage,
            ),
            endDrawer: PracticeAudioDrawer(controller: _controller),
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
                Expanded(child: _buildPage()),
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
    final controller = _controller;
    Widget scrollPage(String key, Widget child) => SingleChildScrollView(
      key: ValueKey(key),
      padding: const EdgeInsets.all(16),
      child: child,
    );

    if (infoPage != null) {
      return scrollPage(infoPage.name, InfoPageView(page: infoPage, readme: _readme));
    }

    return switch (_screen) {
      StudioScreen.varisai => scrollPage(
        'screen-varisai',
        VarisaiStudioScreen(
          controller: controller,
          onAddCustomLesson: _addCustomLesson,
        ),
      ),
      StudioScreen.library => scrollPage(
        'screen-library',
        LessonLibraryScreen(
          lessons: controller.lessons,
          activeLesson: controller.activeLesson,
          onSelectLesson: _selectLesson,
          onAddCustomLesson: _addCustomLesson,
        ),
      ),
      StudioScreen.pitchCoach => scrollPage(
        'screen-pitchCoach',
        PitchCoachScreen(controller: controller),
      ),
      StudioScreen.droneLab => scrollPage(
        'screen-droneLab',
        PracticeAudioScreen(controller: controller),
      ),
    };
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
  final VoidCallback? onHome;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenEndDrawer;

  static const _sessionBarHeight = 48.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + _sessionBarHeight);

  @override
  Widget build(BuildContext context) {
    final audioPlaying = controller.dronePlaying || controller.metronomeOn;
    final ragaLabel = 'Raga: ${controller.raga.name}';
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
        if (onHome != null)
          IconButton(
            tooltip: 'Home (Varisai Studio)',
            onPressed: onHome,
            icon: const Icon(Icons.home_rounded),
          ),
        IconButton(
          tooltip: 'Open practice audio',
          onPressed: onOpenEndDrawer,
          icon: Icon(
            audioPlaying ? Icons.volume_up_rounded : Icons.headphones_rounded,
            color: audioPlaying ? SwaraColors.royalGold : Colors.white70,
          ),
        ),
        const SizedBox(width: 6),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_sessionBarHeight),
        child: SizedBox(
          height: _sessionBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: ragaLabel,
                    excludeFromSemantics: true,
                    child: Text(
                      ragaLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
              ],
            ),
          ),
        ),
      ),
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
        mainAxisSize: MainAxisSize.min,
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
