import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swaraguru/models/models.dart';
import 'package:swaraguru/ui/widgets/swara_grid.dart';

import 'support/fakes.dart';

final double saHz = kDefaultShruti.frequencyHz;

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openPracticeAudio(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open practice audio'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Play Shruti starts a single Sa on harmonium', (tester) async {
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio);

    await openPracticeAudio(tester);
    await tapText(tester, 'Play Shruti');
    await tester.pumpAndSettle();
    expect(audio.drone, droneVoices({saHz: 1}));
    expect(audio.drone!.volume, 0.55);
    expect(audio.drone!.instrument, SwaraInstrument.harmonium);

    await tapText(tester, 'Stop Shruti');
    await tester.pumpAndSettle();
    expect(audio.droneStopped, isTrue);
    expect(find.text('Play Shruti'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(audio.disposed, isTrue);
  });

  testWidgets('Shruti settings switch single-note sounds during playback', (
    tester,
  ) async {
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio, size: const Size(360, 800));
    await openPracticeAudio(tester);
    await tapText(tester, 'Play Shruti');

    await tapText(tester, 'Ṡ (${(saHz * 2).round()} Hz)');
    expect(audio.drone, droneVoices({saHz * 2: 1}));
    expect(audio.drone!.instrument, SwaraInstrument.harmonium);

    final sound = find.byType(DropdownButton<SwaraInstrument>);
    for (final (label, instrument) in [
      ('Piano', SwaraInstrument.piano),
      ('Tampura', SwaraInstrument.tampura),
      ('Harmonium', SwaraInstrument.harmonium),
    ]) {
      await tester.tap(sound);
      await tester.pumpAndSettle();
      expect(find.text('Pure tone'), findsNothing);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(audio.drone!.instrument, instrument);
      expect(audio.drone, droneVoices({saHz * 2: 1}));
    }

    await tapText(tester, 'Multi note');
    expect(audio.drone!.instrument, SwaraInstrument.tampura);
    await tapText(tester, 'Single note');
    expect(audio.drone!.instrument, SwaraInstrument.harmonium);
    await tapText(tester, 'Stop Shruti');
    expect(audio.droneStopped, isTrue);
  });

  testWidgets('Drone start failures are reported', (tester) async {
    final audio = FakeSwaraAudio()..failToStart = true;
    await pumpStudio(tester, audio: audio);

    await openPracticeAudio(tester);
    await tapText(tester, 'Play Shruti');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to play Shruti: Bad state: Audio blocked'),
      findsOneWidget,
    );
    await openPracticeAudio(tester);
    expect(find.text('Play Shruti'), findsOneWidget);
  });

  testWidgets('Varisai plays on the selected instrument', (tester) async {
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio);

    await tapText(tester, 'Practice settings');
    await tapText(tester, 'Piano');
    await tapText(tester, 'Play Varisai');
    expect(audio.activated, isTrue);
    expect(audio.notes.first.instrument, SwaraInstrument.piano);
    expect(audio.notes.first.frequencyHz, closeTo(saHz, 1e-9));

    await tapText(tester, 'Stop Transport');
    expect(audio.stopNotesCalls, 1);
  });

  testWidgets('Session raga retunes the lesson grid', (tester) async {
    await pumpStudio(tester);
    expect(find.text('M1'), findsWidgets);
    await tapText(tester, 'Practice settings');

    final field = find.descendant(
      of: find.byType(DropdownMenu<Raga>),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, 'Kalyani');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Mechakalyani').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Raga: Mechakalyani'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mechakalyani • Adi Tala (8 Beats)'), findsOneWidget);
    expect(find.text('M2'), findsWidgets);
    expect(find.text('M1'), findsNothing);
    expect(
      find.text(
        'Composed in Mayamalavagowla; unnumbered swaras now follow '
        'Mechakalyani.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Scale practice starts avarohanam on a fresh line', (
    tester,
  ) async {
    await pumpStudio(tester);
    await tapText(tester, 'Practice settings');
    await tapText(tester, 'Practice Raga Scale');

    final cells = find.byType(SwaraCell);
    final controller = tester
        .widget<SwaraGrid>(find.byType(SwaraGrid))
        .controller;
    final split = controller.raga.arohanam.length;
    final start = tester.getTopLeft(cells.first);
    expect(tester.getTopLeft(cells.at(split - 1)).dy, start.dy);
    final descent = tester.getTopLeft(cells.at(split));
    expect(descent.dx, start.dx);
    expect(descent.dy, greaterThan(start.dy));
  });

  testWidgets('Sri Gananatha rows follow the Adi grid and selected kaalam', (
    tester,
  ) async {
    await pumpStudio(tester);
    await tapText(tester, 'Library');
    await tapText(tester, 'Geetams');
    await tapText(tester, 'Sri Gananatha (Lambodara) — Malahari');

    final cells = find.byType(SwaraCell);
    Offset startOf(int index) => tester.getTopLeft(cells.at(index));
    expect(startOf(7).dy, startOf(0).dy);
    expect(startOf(8).dx, startOf(0).dx);
    expect(startOf(8).dy, greaterThan(startOf(0).dy));

    final controller = tester
        .widget<SwaraGrid>(find.byType(SwaraGrid))
        .controller;
    controller.selectKaalam(kKaalamOptions[1]);
    await tester.pump();
    expect(startOf(8).dy, startOf(0).dy);
    expect(startOf(8).dx, greaterThan(startOf(0).dx));
  });

  testWidgets('Listen & Identify names the sung swara', (tester) async {
    final pitch = FakePitchSource();
    await pumpStudio(tester, pitchSource: pitch);
    await tapText(tester, 'Live Pitch Coach');

    await tapText(tester, 'Listen & Identify');
    expect(pitch.starts, 1);
    expect(find.text('Stop Listening'), findsOneWidget);

    for (var i = 0; i < 11; i++) {
      pitch.emit(saHz * 1.5);
    }
    await tester.pump();
    expect(find.text('Panchamam'), findsWidgets);
    expect(find.textContaining('Not part of'), findsNothing);

    // Chatushruti Rishabham is outside Mayamalavagowla (R1 G3).
    final r2 = saHz * math.pow(2, 199.2 / 1200);
    for (var i = 0; i < 13; i++) {
      pitch.emit(r2);
    }
    await tester.pump();
    expect(find.text('Not part of Mayamalavagowla'), findsOneWidget);

    await tapText(tester, 'Stop Listening');
    expect(pitch.stops, 1);
    expect(find.text('Listen & Identify'), findsOneWidget);
  });

  testWidgets('Pitch coach lets you set the matching tolerance from 0 to 3%', (
    tester,
  ) async {
    await pumpStudio(tester);
    await tapText(tester, 'Live Pitch Coach');
    final slider = find.byType(Slider);
    await tester.ensureVisible(slider);
    expect(find.text('Pitch tolerance: 1.5%'), findsOneWidget);

    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.left + 1, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Pitch tolerance: 0.0%'), findsOneWidget);

    await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Pitch tolerance: 3.0%'), findsOneWidget);
  });

  testWidgets('Phone tempo controls step from 60 through 200 BPM', (
    tester,
  ) async {
    await pumpStudio(tester, size: const Size(360, 800));
    final slower = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == 'Decrease tempo by 10 BPM',
    );
    final faster = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == 'Increase tempo by 10 BPM',
    );
    expect(tester.widget<IconButton>(slower).onPressed, isNull);
    expect(find.text('60 BPM'), findsOneWidget);
    for (var bpm = 70; bpm <= 200; bpm += 10) {
      await tester.tap(faster);
      await tester.pump();
      expect(find.text('$bpm BPM'), findsOneWidget);
    }
    expect(tester.widget<IconButton>(faster).onPressed, isNull);
    await tester.tap(slower);
    await tester.pump();
    expect(find.text('190 BPM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Metronome is independent of the lesson and follows BPM', (
    tester,
  ) async {
    final metronome = FakeMetronomeAudio();
    await pumpStudio(tester, metronome: metronome);
    await openPracticeAudio(tester);
    await tapText(tester, 'Start metronome');
    expect(metronome.tempos, [60]);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tapText(tester, 'Play Varisai');
    await tester.tap(find.byTooltip('Increase tempo by 10 BPM'));
    await tester.pumpAndSettle();
    expect(metronome.tempos, [60, 70]);
    await tapText(tester, 'Stop Transport');
    await tapText(tester, 'Live Pitch Coach');
    expect(metronome.stops, 0);

    metronome.pauseFromMediaControls();
    await tester.pumpAndSettle();
    await openPracticeAudio(tester);
    await tapText(tester, 'Start metronome');
    expect(metronome.tempos, [60, 70, 70]);

    await tapText(tester, 'Stop metronome');
    expect(metronome.stops, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(metronome.disposed, isTrue);
  });

  testWidgets('Practice audio volume changes both playing sounds', (
    tester,
  ) async {
    final metronome = FakeMetronomeAudio();
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio, metronome: metronome);
    await openPracticeAudio(tester);
    expect(find.byType(Slider), findsOneWidget);
    await tapText(tester, 'Start metronome');
    await tapText(tester, 'Play Shruti');
    expect(audio.drone!.volume, metronome.volume);

    final slider = find.byType(Slider);
    await tester.tapAt(tester.getTopLeft(slider) + const Offset(45, 20));
    await tester.pumpAndSettle();
    expect(audio.drone!.volume, lessThan(0.55));
    expect(audio.drone!.volume, metronome.volume);
    expect(metronome.tempos, [60]); // Volume does not restart the loop.
  });

  testWidgets('Sa picker includes B sharp as an alias of C', (tester) async {
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio);
    await tester.tap(find.byTooltip('Select Base Sa (Adhara Shadjam)'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Sa = C (B#) • 1 Kattai (130.81 Hz)');
    await openPracticeAudio(tester);
    await tapText(tester, 'Play Shruti');
    expect(audio.drone, droneVoices({130.81: 1}));
  });

  testWidgets('Phone header keeps the selected raga and Sa across tabs', (
    tester,
  ) async {
    await pumpStudio(tester, size: const Size(400, 640));
    final header = find.byType(AppBar);
    final raga = find.descendant(
      of: header,
      matching: find.text('Raga: Mayamalavagowla'),
    );
    Finder sa(String label) =>
        find.descendant(of: header, matching: find.text('Sa: $label'));
    expect(raga.hitTestable(), findsOneWidget);
    expect(sa('C#').hitTestable(), findsOneWidget);

    await tester.tap(find.byTooltip('Select Base Sa (Adhara Shadjam)'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Sa = C (B#) • 1 Kattai (130.81 Hz)');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(raga.hitTestable(), findsOneWidget);
    expect(sa('C (B#)').hitTestable(), findsOneWidget);

    for (final tab in ['Pitch Coach', 'Audio', 'Studio']) {
      await tapText(tester, tab);
      expect(raga.hitTestable(), findsOneWidget);
      expect(sa('C (B#)').hitTestable(), findsOneWidget);
    }
  });

  testWidgets('Microphone errors stop listening', (tester) async {
    final pitch = FakePitchSource()..failWith = StateError('Denied');
    await pumpStudio(tester, pitchSource: pitch);
    await tapText(tester, 'Live Pitch Coach');

    await tapText(tester, 'Listen & Identify');
    expect(
      find.text('Microphone unavailable: Bad state: Denied'),
      findsOneWidget,
    );
    expect(find.text('Listen & Identify'), findsOneWidget);
  });

  testWidgets('Sing & Match holds the microphone until stopped', (
    tester,
  ) async {
    final pitch = FakePitchSource();
    await pumpStudio(tester, pitchSource: pitch);

    await tapText(tester, 'Sing & Match Swaras');
    expect(pitch.starts, 1);
    expect(pitch.isActive, isTrue);

    await tapText(tester, 'Stop Transport');
    expect(pitch.stops, 1);
    expect(find.text('Sing & Match Swaras'), findsOneWidget);
  });

  testWidgets('Help, privacy, and license are reachable from navigation', (
    tester,
  ) async {
    await pumpStudio(tester);

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
    expect(find.textContaining('## ', findRichText: true), findsNothing);
    expect(find.byType(Table), findsWidgets);
    expect(
      find.textContaining('Shared volume', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Microphone audio is never recorded, stored, or uploaded',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('secure context', findRichText: true),
      findsOneWidget,
    );
    for (final developerOnly in ['Getting started', 'git clone']) {
      expect(
        find.textContaining(developerOnly, findRichText: true),
        findsNothing,
      );
    }
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
      find.textContaining('never recorded, stored, or transmitted'),
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
    await pumpStudio(tester);
    await tester.tap(find.byTooltip('Open Navigation & Varisai Drawer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Library'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Sarali Varisai');
    await tapText(tester, 'Combo 2');

    await tester.tap(find.text('Practice Audio'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Practice Audio'),
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
    expect(find.text('Sarali Varisai 2'), findsOneWidget);
  });

  testWidgets('Phone Library opens combos and Geetams by category', (
    tester,
  ) async {
    await pumpStudio(tester, size: const Size(360, 640));
    final library = find.widgetWithText(NavigationDestination, 'Library');
    await tester.tap(library);
    await tester.pumpAndSettle();

    expect(find.text('Combo 1'), findsNothing);
    expect(find.textContaining('Devi Sthuthi'), findsNothing);
    await tapText(tester, 'Janta Varisai');
    final lastCombo = find.widgetWithText(OutlinedButton, 'Combo 15');
    expect(lastCombo.hitTestable(), findsOneWidget);
    await tester.tap(lastCombo);
    await tester.pumpAndSettle();
    expect(find.text('Janta Varisai 15'), findsOneWidget);

    await tester.tap(library);
    await tester.pumpAndSettle();
    await tapText(tester, 'Dhatu Varisai');
    expect(find.text('Combo 8'), findsOneWidget);
    expect(find.text('Combo 9'), findsNothing);
    await tapText(tester, 'All categories');
    await tapText(tester, 'Geetams');
    expect(find.text('Sri Gananatha (Lambodara) — Malahari'), findsOneWidget);
    await tapText(tester, 'Devi Sthuthi — Sree Saraswathi');
    expect(find.text('Devi Sthuthi — Sree Saraswathi'), findsOneWidget);
    expect(find.textContaining('Arabhi • Roopaka'), findsOneWidget);
  });

  testWidgets('Beat strip fits one row and shows the current kriya', (
    tester,
  ) async {
    Future<void> showBeat(int? beat) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 288,
              child: AdiTalaBeatStrip(activeBeat: beat),
            ),
          ),
        ),
      ),
    );

    await showBeat(null);
    Finder beatTooltip(String label) => find.byWidgetPredicate(
      (widget) => widget is Tooltip && widget.message == label,
    );
    final first = beatTooltip('Beat 1 • Clap (Laghu)');
    final last = beatTooltip('Beat 8 • Wave');
    final row = tester.getCenter(first).dy;
    expect(tester.getCenter(last).dy, row);
    expect(tester.getCenter(find.text('Adi tala')).dy, row);
    expect(tester.getSize(find.byType(AdiTalaBeatStrip)).height, lessThan(30));

    await showBeat(4);
    expect(find.text('Finger 3'), findsOneWidget);
    final fourth = beatTooltip('Beat 4 • Finger 3');
    final marker = find.descendant(
      of: fourth,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Beat 4 • Finger 3',
      ),
    );
    expect(tester.widget<Semantics>(marker).properties.selected, isTrue);
    expect(
      tester.getCenter(find.text('Finger 3')).dy,
      tester.getCenter(fourth).dy,
    );
  });

  testWidgets('Single-row Sarali keeps written beat groups together', (
    tester,
  ) async {
    await pumpStudio(tester);
    final cells = find.byType(SwaraCell);
    Rect bounds(int i) => tester.getRect(cells.at(i));
    expect(bounds(3).top, bounds(0).top);
    expect(bounds(4).top, bounds(3).top);
    expect(
      bounds(4).left - bounds(3).right,
      greaterThan(bounds(1).left - bounds(0).right),
    );

    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(bounds(3).top, bounds(0).top);
    expect(bounds(4).left, bounds(0).left);
    expect(bounds(4).top, greaterThan(bounds(3).bottom));
    expect(bounds(7).top, bounds(4).top);
  });

  testWidgets('Long scores build on demand and update only changed cells', (
    tester,
  ) async {
    await pumpStudio(tester, size: const Size(360, 640));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Library'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Janta Varisai');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Combo 15'));
    await tester.pumpAndSettle();

    expect(find.text('Janta Varisai 15'), findsOneWidget);
    final controller = tester
        .widget<SwaraGrid>(find.byType(SwaraGrid, skipOffstage: false))
        .controller;
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(220);
    await tester.pump();
    final cells = find.byType(SwaraCell, skipOffstage: false);
    final count = cells.evaluate().length;
    expect(count, inInclusiveRange(4, controller.steps.length ~/ 2));
    expect(
      tester.getTopLeft(cells.at(0)).dy,
      tester.getTopLeft(cells.at(3)).dy,
    );
    double top(int i) => tester.getTopLeft(cells.at(i)).dy;
    expect(top(4), greaterThan(top(0)));
    expect(
      tester.getTopLeft(cells.at(16)).dx,
      tester.getTopLeft(cells.at(0)).dx,
    );
    expect(top(16) - top(12), greaterThan(top(4) - top(0)));

    SwaraCell cell(int index) => tester.widget<SwaraCell>(cells.at(index));
    await controller.playReference();
    await tester.pump();
    expect(cell(0).isActive, isTrue);
    final unchanged = cell(3);
    await tester.pump(controller.stepDuration);
    expect(cell(0).isActive, isFalse);
    expect(cell(1).isActive, isTrue);
    expect(cell(3), same(unchanged));

    controller.stopTransport();
    scroll.position.jumpTo(1000);
    await tester.pump();
    expect(find.byWidget(unchanged), findsNothing);
    expect(cells, findsWidgets);
  });

  testWidgets('Mobile drawer scrolls to Help and Home restores navigation', (
    tester,
  ) async {
    await pumpStudio(tester, size: const Size(360, 640));
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
