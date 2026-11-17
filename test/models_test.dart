import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swaraguru/models/models.dart';

import 'support/fakes.dart';

void main() {
  final catalog = loadTestCatalog();

  group('Tuning', () {
    test('Sa, Ma, Pa and Tara Sa are pure intervals', () {
      expect(Swara.s.ratio, 1);
      expect(Swara.m1.ratio, closeTo(4 / 3, 1e-12));
      expect(Swara.p.ratio, closeTo(3 / 2, 1e-12));
      expect(const SwaraNote(Swara.s, 1).ratio, 2);
      expect(const SwaraNote(Swara.p, -1).ratio, closeTo(0.75, 1e-12));
    });

    test('Other swarasthanas are interpolated between the anchors', () {
      final ma1 = centsForRatio(4 / 3);
      final pa = centsForRatio(3 / 2);
      expect(Swara.r1.cents, closeTo(ma1 / 5, 1e-9));
      expect(Swara.g3.cents, closeTo(ma1 * 4 / 5, 1e-9));
      expect(Swara.m2.cents, closeTo((ma1 + pa) / 2, 1e-9));
      expect(Swara.n3.cents, closeTo(pa + (1200 - pa) * 4 / 5, 1e-9));
      // Enharmonic names share a pitch.
      expect(Swara.r2.ratio, Swara.g1.ratio);
      expect(Swara.d3.ratio, Swara.n2.ratio);
    });
  });

  group('Shruti pitches', () {
    test('match the iSruthi base-Sa table', () {
      expect(
        {for (final s in kShrutiPitches) s.label: s.frequencyHz},
        {
          'A': 110.00,
          'A#': 116.54,
          'B': 123.47,
          'C': 130.81,
          'C#': 138.59,
          'D': 146.83,
          'D#': 155.56,
          'E': 164.81,
          'F': 174.61,
          'F#': 185.00,
          'G': 196.00,
          'G#': 207.65,
        },
      );
      expect(kDefaultShruti.label, 'C#');
      expect(kDefaultShruti.kattaiName, '1½ Kattai');
      expect(kShrutiPitches.first.kattaiName, '6 Kattai');
    });

    test('are a semitone apart', () {
      for (var i = 1; i < kShrutiPitches.length; i++) {
        final cents = centsForRatio(
          kShrutiPitches[i].frequencyHz / kShrutiPitches[i - 1].frequencyHz,
        );
        expect(cents, closeTo(100, 1), reason: kShrutiPitches[i].label);
      }
    });
  });

  group('Notation', () {
    test('parses variants, octaves and default letters', () {
      expect('R2'.toSwaraNote(), const SwaraNote(Swara.r2));
      expect('g'.toSwaraNote(), const SwaraNote(Swara.g3));
      expect('Ṡ'.toSwaraNote(), const SwaraNote(Swara.s, 1));
      expect("S'".toSwaraNote(), const SwaraNote(Swara.s, 1));
      expect('N.'.toSwaraNote(), const SwaraNote(Swara.n3, -1));
      expect('Ṇ'.toSwaraNote(), const SwaraNote(Swara.n3, -1));
      expect('P4'.toSwaraNote(), isNull);
      expect('X'.toSwaraNote(), isNull);
      expect(() => parseSwaraNotes('S R Q'), throwsFormatException);
    });

    test('labels round-trip through the parser', () {
      for (final swara in Swara.values) {
        for (final octave in [-1, 0, 1]) {
          final note = SwaraNote(swara, octave);
          expect(note.label.toSwaraNote(), note, reason: note.label);
        }
      }
    });

    test('names notes by octave', () {
      expect(const SwaraNote(Swara.s).fullName, 'Adhara Shadjam');
      expect(const SwaraNote(Swara.m2).fullName, 'Prati Madhyamam');
      expect(const SwaraNote(Swara.s, 1).fullName, 'Tara Shadjam');
      expect(const SwaraNote(Swara.p, -1).fullName, 'Mandra Panchamam');
    });
  });

  group('JSON', () {
    test('SwaraNote, Raga and lesson round-trip', () {
      const note = SwaraNote(Swara.d1, -1);
      expect(SwaraNote.fromJson(note.toJson()), note);

      final kalyani = catalog.ragaNamed('Kalyani')!;
      final raga = Raga.fromJson(
        jsonDecode(jsonEncode(kalyani)) as Map<String, dynamic>,
      );
      expect(raga.name, 'Mechakalyani');
      expect(raga.aliases, ['Kalyani']);
      expect(raga.arohanam, kalyani.arohanam);
      expect(raga.avarohanam, kalyani.avarohanam);

      final lesson = catalog.lessons.last;
      final json = lesson.toJson();
      expect(json['notation'], lesson.swaras.join(' '));
      expect(CarnaticLesson.fromJson(json).swaras, lesson.swaras);
    });

    test('DroneSettings round-trip', () {
      final settings = DroneSettings(
        mode: DroneMode.pureSingleNote,
        pureChannel: DroneChannel.ni3,
        mix: DronePreset.ni.mix,
        volume: 0.4,
        instrument: SwaraInstrument.piano,
      );
      final copy = DroneSettings.fromJson(
        jsonDecode(jsonEncode(settings)) as Map<String, dynamic>,
      );
      expect(copy.mode, settings.mode);
      expect(copy.pureChannel, settings.pureChannel);
      expect(copy.mix, settings.mix);
      expect(copy.volume, settings.volume);
      expect(copy.instrument, settings.instrument);
    });

    test('catalog round-trips', () {
      final copy = CarnaticCatalog.fromJson(
        jsonDecode(jsonEncode(catalog)) as Map<String, dynamic>,
      );
      expect(copy.ragas.length, catalog.ragas.length);
      expect(copy.lessons.map((l) => l.id), catalog.lessons.map((l) => l.id));
    });
  });

  group('Catalog', () {
    test('contains all 72 melakartas with the standard swaras', () {
      const riGa = [
        [Swara.r1, Swara.g1],
        [Swara.r1, Swara.g2],
        [Swara.r1, Swara.g3],
        [Swara.r2, Swara.g2],
        [Swara.r2, Swara.g3],
        [Swara.r3, Swara.g3],
      ];
      const dhaNi = [
        [Swara.d1, Swara.n1],
        [Swara.d1, Swara.n2],
        [Swara.d1, Swara.n3],
        [Swara.d2, Swara.n2],
        [Swara.d2, Swara.n3],
        [Swara.d3, Swara.n3],
      ];
      for (var n = 1; n <= 72; n++) {
        final raga = catalog.melakarta(n);
        expect(raga, isNotNull, reason: 'Mela $n');
        expect(raga!.swaras, {
          Swara.s,
          ...riGa[((n - 1) % 36) ~/ 6],
          n <= 36 ? Swara.m1 : Swara.m2,
          Swara.p,
          ...dhaNi[(n - 1) % 6],
        }, reason: raga.name);
      }
    });

    test('janya ragas use swaras of their parent melakarta', () {
      for (final raga in catalog.ragas.where((r) => !r.isMelakarta)) {
        final parent = catalog.melakarta(raga.parentMelakarta!);
        expect(parent, isNotNull, reason: raga.name);
        expect(parent!.swaras.containsAll(raga.swaras), isTrue);
      }
    });

    test('finds ragas by alias and loose name', () {
      expect(catalog.ragaNamed('Kalyani')!.melakarta, 65);
      expect(catalog.ragaNamed('todi')!.name, 'Hanumatodi');
      expect(catalog.ragaNamed('Shankarabharanam')!.melakarta, 29);
      expect(
        catalog.ragaNamed('Mayamalavagowla (15th Melakarta)'),
        catalog.melakarta(15),
      );
      expect(catalog.ragaNamed('Unknown'), isNull);
    });

    test('lessons resolve in their raga', () {
      expect(catalog.lessons, isNotEmpty);
      for (final lesson in catalog.lessons) {
        final raga = catalog.ragaNamed(lesson.raga);
        expect(raga, isNotNull, reason: lesson.id);
        expect(lesson.invalidTokens, isEmpty, reason: lesson.id);
        final steps = lesson.stepsFor(catalog.scaleFor(raga!));
        expect(steps.every((s) => s.note != null), isTrue);
        expect(
          steps.every((s) => raga.swaras.contains(s.note!.swara)),
          isTrue,
          reason: lesson.id,
        );
      }
    });

    test('karvai sustains the previous swara', () {
      final steps = CarnaticLesson(
        id: 't',
        group: 'g',
        title: 't',
        raga: 'Mayamalavagowla',
        swaras: tokenizeNotation(' S  , R '),
      ).stepsFor(catalog.scaleFor(catalog.defaultRaga));
      expect(steps.map((s) => s.label), ['S', ',', 'R1']);
      expect(steps[1].isKarvai, isTrue);
      expect(steps[1].note, const SwaraNote(Swara.s));
    });

    testWidgets('loads from the asset bundle', (tester) async {
      final loaded = (await tester.runAsync(
        () => CarnaticCatalog.load(rootBundle),
      ))!;
      expect(loaded.ragas.length, catalog.ragas.length);
      expect(loaded.defaultRaga.name, 'Mayamalavagowla');
      expect(loaded.lessons.length, catalog.lessons.length);
    });
  });
}
