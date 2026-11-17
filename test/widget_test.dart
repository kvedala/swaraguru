import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swaraguru/models/models.dart';

import 'support/fakes.dart';

final double saHz = kDefaultShruti.frequencyHz;

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Play Shruti starts the default tampura drone', (tester) async {
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio);

    await tapText(tester, 'Play Shruti');
    expect(
      audio.drone,
      droneVoices({
        saHz * 0.75: 0.45,
        saHz: 0.95,
        saHz * 1.5: 0.80,
        saHz * 2: 0.70,
      }),
    );
    expect(audio.drone!.volume, 0.55);
    expect(audio.drone!.instrument, SwaraInstrument.tampura);

    await tapText(tester, 'Stop Shruti');
    expect(audio.droneStopped, isTrue);
    expect(find.text('Play Shruti'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(audio.disposed, isTrue);
  });

  testWidgets('Drone Lab renders a pure Tara Sa on the harmonium', (
    tester,
  ) async {
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio);
    await tapText(tester, 'Shruti Drone Lab');
    await tapText(tester, 'Start Drone');

    await tapText(tester, 'Pure Single Note');
    await tapText(tester, 'Ṡ (${(saHz * 2).round()} Hz)');
    expect(audio.drone, droneVoices({saHz * 2: 1}));

    await tapText(tester, 'Harmonium');
    expect(audio.drone!.instrument, SwaraInstrument.harmonium);
    expect(find.text('Shruti Box: Pure Ṡ'), findsOneWidget);
  });

  testWidgets('Drone start failures are reported', (tester) async {
    final audio = FakeSwaraAudio()..failToStart = true;
    await pumpStudio(tester, audio: audio);

    await tapText(tester, 'Play Shruti');
    expect(
      find.text('Unable to play Shruti: Bad state: Audio blocked'),
      findsOneWidget,
    );
    expect(find.text('Play Shruti'), findsOneWidget);
  });

  testWidgets('Varisai plays on the selected instrument', (tester) async {
    final audio = FakeSwaraAudio();
    await pumpStudio(tester, audio: audio);

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

    expect(find.text('Raga: Mechakalyani (Melakarta 65)'), findsOneWidget);
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

  testWidgets('Listen & Identify names the sung swara', (tester) async {
    final pitch = FakePitchSource();
    await pumpStudio(tester, pitchSource: pitch);
    await tapText(tester, 'Live Pitch Coach');

    await tapText(tester, 'Listen & Identify');
    expect(pitch.starts, 1);
    expect(find.text('Stop Listening'), findsOneWidget);

    pitch.emit(saHz * 1.5);
    await tester.pump();
    expect(find.text('Panchamam'), findsWidgets);
    expect(find.textContaining('Not part of'), findsNothing);

    // Chatushruti Rishabham is outside Mayamalavagowla (R1 G3).
    final r2 = saHz * math.pow(2, 199.2 / 1200);
    for (var i = 0; i < 3; i++) {
      pitch.emit(r2);
    }
    await tester.pump();
    expect(find.text('Not part of Mayamalavagowla'), findsOneWidget);

    await tapText(tester, 'Stop Listening');
    expect(pitch.stops, 1);
    expect(find.text('Listen & Identify'), findsOneWidget);
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
