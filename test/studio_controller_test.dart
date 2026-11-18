import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:swaraguru/models/models.dart';
import 'package:swaraguru/studio/pitch_display.dart';
import 'package:swaraguru/studio/studio_controller.dart';

import 'support/fakes.dart';

final CarnaticCatalog catalog = loadTestCatalog();
final double saHz = kDefaultShruti.frequencyHz;

double shifted(double hz, double cents) => hz * math.pow(2, cents / 1200);

/// Runs [body] with a controller that is always disposed, so no transport
/// timer outlives the test.
Future<void> withController(
  Future<void> Function(
    StudioController controller,
    FakeSwaraAudio audio,
    FakePitchSource pitch,
  )
  body,
) async {
  final audio = FakeSwaraAudio();
  final pitch = FakePitchSource();
  final controller = StudioController(
    catalog: catalog,
    audio: audio,
    pitchSource: pitch,
    random: math.Random(7),
  );
  try {
    await body(controller, audio, pitch);
  } finally {
    controller.dispose();
  }
}

void main() {
  testWidgets('Reference playback sustains swaras through karvai', (
    tester,
  ) async {
    await withController((controller, audio, _) async {
      controller.addCustomLesson(
        title: 'Karvai',
        raga: catalog.defaultRaga,
        tokens: ['S', ',', 'R', 'G', ',', ','],
      );
      final step = controller.stepDuration;
      expect(step, const Duration(seconds: 1));

      await controller.playReference();
      await tester.pump(step * 6);
      expect(controller.isTransportRunning, isFalse);

      final r1 = Swara.r1.frequencyFor(saHz);
      final g3 = Swara.g3.frequencyFor(saHz);
      expect(
        [for (final note in audio.notes) note.frequencyHz],
        [saHz, r1, g3],
      );
      expect(
        [for (final note in audio.notes) note.duration],
        [step * (2 * 0.94), step * 0.94, step * (3 * 0.94)],
      );
      expect(
        audio.notes.map((note) => note.instrument),
        everyElement(SwaraInstrument.harmonium),
      );
    });
  });

  testWidgets('Unsupported audio falls back to visual playback once', (
    tester,
  ) async {
    await withController((controller, audio, _) async {
      final notices = <String>[];
      controller.onNotice = notices.add;
      audio.activateError = UnsupportedError('No instrument audio here.');

      await controller.playReference();
      expect(controller.isPlayingReference, isTrue);
      controller.stopTransport();
      await controller.playReference();
      controller.stopTransport();

      expect(notices, [
        'No instrument audio here. Showing visual playback only.',
      ]);
    });
  });

  testWidgets('Session raga re-resolves unnumbered swaras', (tester) async {
    await withController((controller, _, _) async {
      List<String> firstOctave() => [
        for (final step in controller.steps.take(8)) step.label,
      ];

      expect(firstOctave(), ['S', 'R1', 'G3', 'M1', 'P', 'D1', 'N3', 'Ṡ']);
      expect(controller.suggestedDronePreset, DronePreset.pa);

      // Mohanam omits Ma and Ni, so they come from Harikambhoji (28).
      controller.selectRaga(catalog.ragaNamed('Mohanam')!);
      expect(firstOctave(), ['S', 'R2', 'G3', 'M1', 'P', 'D2', 'N2', 'Ṡ']);

      controller.selectRaga(catalog.ragaNamed('Kalyani')!);
      expect(firstOctave(), ['S', 'R2', 'G3', 'M2', 'P', 'D2', 'N3', 'Ṡ']);

      controller.selectRaga(catalog.ragaNamed('Hindolam')!);
      expect(controller.suggestedDronePreset, DronePreset.ma);
      controller.selectRaga(catalog.ragaNamed('Hamsanandi')!);
      expect(controller.suggestedDronePreset, DronePreset.ni);

      controller.selectLesson(controller.lessons.first);
      expect(controller.raga.name, 'Mayamalavagowla');
    });
  });

  testWidgets('Microphone coaching grades each swara and frees the mic', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      controller.addCustomLesson(
        title: 'Mic',
        raga: catalog.defaultRaga,
        tokens: ['S', 'R', 'G', 'M', 'P'],
      );
      final step = controller.stepDuration;
      await controller.startCoaching();
      expect(pitch.starts, 1);
      expect(controller.activeStepIndex, 0);

      final sung = <double?>[
        saHz,
        Swara.r2.frequencyFor(saHz),
        shifted(Swara.g3.frequencyFor(saHz), 40),
        null,
        saHz * 3,
      ];
      for (final hz in sung) {
        for (var i = 0; i < 4; i++) {
          pitch.emit(hz);
        }
        await tester.pump(step);
      }

      final results = controller.evaluations;
      expect(
        [for (var i = 0; i < 5; i++) results[i]!.status],
        [
          NoteMatchStatus.match,
          NoteMatchStatus.wrongSwara,
          NoteMatchStatus.apasruti,
          NoteMatchStatus.noVoice,
          NoteMatchStatus.match,
        ],
      );
      expect(results[1]!.sung!.label, 'R2');
      expect(results[2]!.message, 'G3 was a little too high.');
      expect(results[4]!.sung, const SwaraNote(Swara.p, 1));

      expect(controller.isCoaching, isFalse);
      expect(controller.microphoneActive, isFalse);
      expect(pitch.stops, 1);
    });
  });

  testWidgets('Simulated student sings R2 for R1 without the microphone', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      controller.setCoachInput(CoachInput.simulatedStudent);
      await controller.startCoaching();
      await tester.pump(controller.stepDuration);

      expect(pitch.starts, 0);
      expect(controller.evaluations[1]!.status, NoteMatchStatus.wrongSwara);
      expect(controller.evaluations[1]!.sung!.swara, Swara.r2);
      controller.stopTransport();
    });
  });

  testWidgets('Listening and coaching share one microphone session', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      await controller.toggleListening();
      await controller.startCoaching();
      expect(pitch.starts, 1);

      controller.stopTransport();
      expect(controller.microphoneActive, isTrue);

      await controller.toggleListening();
      expect(controller.microphoneActive, isFalse);
      expect(pitch.stops, 1);
    });
  });

  testWidgets('Coaching cancelled while the mic starts releases it', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      final starting = controller.startCoaching();
      controller.stopTransport();
      await starting;

      expect(controller.isCoaching, isFalse);
      expect(controller.microphoneActive, isFalse);
      expect(pitch.starts, 1);
      expect(pitch.stops, 1);
    });
  });

  testWidgets('Changing coach input cancels a pending mic coaching start', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      final starting = controller.startCoaching();
      controller.setCoachInput(CoachInput.simulatedStudent);
      await starting;

      expect(controller.isCoaching, isFalse);
      expect(controller.microphoneActive, isFalse);
      expect(pitch.stops, 1);
    });
  });

  testWidgets('A repeated coaching request keeps the starting mic', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      final first = controller.startCoaching();
      final second = controller.startCoaching();
      await Future.wait([first, second]);

      expect(controller.isCoaching, isTrue);
      expect(controller.microphoneActive, isTrue);
      expect(pitch.starts, 1);
      expect(pitch.stops, 0);
    });
  });

  testWidgets('Stopping listening while the mic starts releases it', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      final starting = controller.toggleListening();
      await controller.toggleListening();
      await starting;

      expect(controller.isListening, isFalse);
      expect(controller.microphoneActive, isFalse);
      expect(pitch.starts, 1);
      expect(pitch.stops, 1);
    });
  });

  testWidgets('Live swara needs a quarter second and clears after silence', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      await controller.toggleListening();
      void emit(double? hz, int frames) {
        for (var i = 0; i < frames; i++) {
          pitch.emit(hz);
        }
      }

      emit(saHz, 10);
      expect(controller.pitchDisplay.value, PitchDisplay.listening);
      emit(null, 1);
      emit(saHz, 10);
      expect(controller.pitchDisplay.value, PitchDisplay.listening);
      emit(saHz, 1);
      expect(controller.pitchDisplay.value.label, 'S');

      final paHz = Swara.p.frequencyFor(saHz);
      emit(paHz, 4);
      emit(saHz, 8);
      expect(controller.pitchDisplay.value.label, 'S');

      emit(paHz, 12);
      expect(controller.pitchDisplay.value.label, 'S');
      emit(paHz, 1);
      expect(controller.pitchDisplay.value.label, 'P');

      emit(null, 14);
      expect(controller.pitchDisplay.value.label, 'P');
      emit(null, 1);
      expect(controller.pitchDisplay.value, PitchDisplay.listening);
    });
  });

  testWidgets('Live pitch hold follows audio time at a different cadence', (
    tester,
  ) async {
    await withController((controller, _, pitch) async {
      pitch.readingInterval = const Duration(milliseconds: 50);
      await controller.toggleListening();
      for (var i = 0; i < 4; i++) {
        pitch.emit(saHz);
      }
      expect(controller.pitchDisplay.value, PitchDisplay.listening);
      pitch.emit(saHz);
      expect(controller.pitchDisplay.value.label, 'S');
    });
  });

  testWidgets('Tempo changes take effect at the next step of playback', (
    tester,
  ) async {
    await withController((controller, audio, _) async {
      controller.addCustomLesson(
        title: 'Tempo',
        raga: catalog.defaultRaga,
        tokens: ['S', 'R', 'G', 'M', 'P'],
      );
      final slow = controller.stepDuration;
      await controller.playReference();
      controller.setBpm(140);
      final fast = controller.stepDuration;

      await tester.pump(slow);
      expect(controller.activeStepIndex, 1);
      await tester.pump(fast);
      await tester.pump(fast);
      expect(controller.activeStepIndex, 3);
      expect(
        [for (final note in audio.notes) note.duration],
        [slow * 0.94, fast * 0.94, fast * 0.94, fast * 0.94],
      );
    });
  });

  testWidgets('Reference tempo changes wait until after a karvai', (
    tester,
  ) async {
    await withController((controller, audio, _) async {
      controller.addCustomLesson(
        title: 'Tempo Karvai',
        raga: catalog.defaultRaga,
        tokens: ['S', ',', ',', 'R', 'G'],
      );
      final slow = controller.stepDuration;
      await controller.playReference();
      controller.setBpm(140);
      final fast = controller.stepDuration;

      await tester.pump(slow);
      expect(controller.activeStepIndex, 1);
      await tester.pump(slow);
      expect(controller.activeStepIndex, 2);
      await tester.pump(slow);
      expect(controller.activeStepIndex, 3);
      expect(audio.notes[0].duration, slow * (3 * 0.94));

      await tester.pump(fast);
      expect(controller.activeStepIndex, 4);
      expect(audio.notes[1].duration, fast * 0.94);
    });
  });

  testWidgets('Single note follows Sa and a preset switches to Tampura', (
    tester,
  ) async {
    await withController((controller, audio, _) async {
      await controller.toggleDrone();
      final d = kShrutiPitches.firstWhere((s) => s.label == 'D');
      controller.selectShruti(d);
      expect(audio.drone, droneVoices({d.frequencyHz: 1}));
      expect(audio.drone!.instrument, SwaraInstrument.harmonium);

      controller.applyDronePreset(DronePreset.ma);
      expect(audio.drone!.instrument, SwaraInstrument.tampura);
      expect(
        audio.drone,
        droneVoices({
          controller.saHz: 0.95,
          controller.saHz * 4 / 3: 0.80,
          controller.saHz * 2: 0.70,
        }),
      );
    });
  });
}
