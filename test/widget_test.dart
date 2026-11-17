import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swaraguru/main.dart';
import 'package:swaraguru/shruti_audio.dart';

class FakeShrutiAudio implements ShrutiAudio {
  Map<double, double> voices = {};
  double volume = 0;
  bool stopped = false;
  bool disposed = false;
  bool failToStart = false;

  @override
  Future<void> start(Map<double, double> voices, double volume) async {
    if (failToStart) throw StateError('Audio blocked');
    update(voices, volume);
  }

  @override
  void update(Map<double, double> voices, double volume) {
    this.voices = Map.of(voices);
    this.volume = volume;
  }

  @override
  void stop() => stopped = true;

  @override
  Future<void> dispose() async => disposed = true;
}

class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle(this.readme);

  final String readme;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == 'README.md'
      ? Future.value(readme)
      : rootBundle.loadString(key, cache: cache);
}

Future<void> pumpStudio(
  WidgetTester tester,
  FakeShrutiAudio audio, {
  Size size = const Size(1600, 1200),
}) async {
  final readme = await tester.runAsync(
    () => rootBundle.loadString('README.md'),
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: TestAssetBundle(readme!),
      child: MaterialApp(home: SwaraGuruAdaptiveScaffold(shrutiAudio: audio)),
    ),
  );
}

void main() {
  testWidgets(
    'Play starts mixed audio, Stop ends it, disposal releases audio',
    (tester) async {
      final audio = FakeShrutiAudio();
      await pumpStudio(tester, audio);

      await tester.tap(find.text('Play Shruti'));
      await tester.pump();

      final sa = kShrutiList[1].frequencyHz;
      expect(audio.voices, {
        sa * math.pow(2, -500 / 1200): 0.45,
        sa: 0.95,
        sa * math.pow(2, 700 / 1200): 0.80,
        sa * 2: 0.70,
      });
      expect(audio.volume, 0.55);
      expect(find.text('Stop Shruti'), findsOneWidget);

      await tester.tap(find.text('Stop Shruti'));
      await tester.pump();
      expect(audio.stopped, isTrue);
      expect(find.text('Play Shruti'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(audio.disposed, isTrue);
    },
  );

  testWidgets('Mixer mode changes update playing audio', (tester) async {
    final audio = FakeShrutiAudio();
    await pumpStudio(tester, audio);
    await tester.tap(find.text('Play Shruti'));
    await tester.pump();
    await tester.tap(find.text('Shruti Drone Lab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pure Single Note'));
    await tester.pumpAndSettle();

    expect(audio.voices, {kShrutiList[1].frequencyHz: 1.0});
    final highSa = kShrutiList[1].frequencyHz * 2;
    await tester.tap(find.textContaining('(${highSa.round()} Hz)'));
    await tester.pump();
    expect(audio.voices, {highSa: 1.0});
  });

  testWidgets('Playback errors are visible and do not show playing state', (
    tester,
  ) async {
    final audio = FakeShrutiAudio()..failToStart = true;
    await pumpStudio(tester, audio);
    await tester.tap(find.text('Play Shruti'));
    await tester.pump();

    expect(find.textContaining('Unable to play Shruti:'), findsOneWidget);
    expect(find.text('Stop Shruti'), findsNothing);
    expect(find.text('Play Shruti'), findsOneWidget);
    expect(audio.stopped, isTrue);
  });

  testWidgets('Help, privacy, and license are reachable from navigation', (
    tester,
  ) async {
    await pumpStudio(tester, FakeShrutiAudio());

    await tester.tap(find.byTooltip('Open Navigation & Varisai Drawer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Help'));
    await tester.pumpAndSettle();
    expect(
      find.text('Guides and answers for using SwaraGuru.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Current capabilities', findRichText: true),
      findsOneWidget,
    );
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      isNull,
    );

    await tester.tap(find.byTooltip('Open Navigation & Varisai Drawer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Privacy Policy'));
    await tester.pumpAndSettle();
    expect(
      find.text('How SwaraGuru handles information and audio.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not request or use microphone access'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Open Navigation & Varisai Drawer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'License'));
    await tester.pumpAndSettle();
    expect(
      find.text('The terms for using SwaraGuru source code.'),
      findsOneWidget,
    );
    expect(find.textContaining('Permission is hereby granted'), findsOneWidget);
  });

  testWidgets('Home returns to the studio and preserves the selected lesson', (
    tester,
  ) async {
    await pumpStudio(tester, FakeShrutiAudio());
    await tester.tap(find.byTooltip('Open Navigation & Varisai Drawer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sarali Varisai 2 — Shadja-Rishabha Anchor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shruti Drone Lab'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Shruti Drone Lab'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Home (Varisai Studio)'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Varisai Studio'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Sarali Varisai 2 — Shadja-Rishabha Anchor'),
      findsOneWidget,
    );
  });

  testWidgets('Mobile drawer scrolls to Help and Home restores navigation', (
    tester,
  ) async {
    await pumpStudio(tester, FakeShrutiAudio(), size: const Size(360, 640));
    await tester.tap(find.byTooltip('Open Navigation & Varisai Drawer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Help'),
      200,
      scrollable: find.descendant(
        of: find.byType(Drawer).first,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.widgetWithText(ListTile, 'Help'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Help')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Home (Varisai Studio)'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
