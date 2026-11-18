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
        {for (final s in kShrutiPitches) s.id: s.frequencyHz},
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

      final lesson = catalog.lessons.singleWhere((l) => l.id == 'geetham-1');
      final json = lesson.toJson();
      expect(json['notation'], lesson.swaras.join(' '));
      expect(CarnaticLesson.fromJson(json).swaras, lesson.swaras);
    });

    test('DroneSettings round-trip', () {
      final settings = DroneSettings(
        mode: DroneMode.pureSingleNote,
        pureChannel: DroneChannel.ni3,
        singleNoteInstrument: SwaraInstrument.harmonium,
        mix: DronePreset.ni.mix,
        volume: 0.4,
        instrument: SwaraInstrument.piano,
      );
      final copy = DroneSettings.fromJson(
        jsonDecode(jsonEncode(settings)) as Map<String, dynamic>,
      );
      expect(copy.mode, settings.mode);
      expect(copy.pureChannel, settings.pureChannel);
      expect(copy.soundFor(140).instrument, SwaraInstrument.harmonium);
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

    test('imports one score per numbered Foundation combo', () {
      for (final (prefix, count) in [
        ('sarali', 14),
        ('janta', 15),
        ('dhatu', 8),
      ]) {
        final lessons = catalog.lessons.where(
          (l) => l.id.startsWith('$prefix-'),
        );
        expect(lessons.map((l) => l.combo), List.generate(count, (i) => i + 1));
        for (final lesson in lessons) {
          expect(lesson.notationRows, isNotEmpty, reason: lesson.id);
          expect(
            lesson.notationRows!.map((row) => row.length),
            everyElement(8),
          );
        }
      }

      CarnaticLesson lesson(String id) =>
          catalog.lessons.singleWhere((l) => l.id == id);
      expect(lesson('sarali-1').notationRows!.first.take(2), [
        'S R S R',
        'S R G M',
      ]);
      expect(lesson('sarali-14').notationRows, hasLength(4));
      expect(lesson('janta-9').notationRows, hasLength(20));
      expect(lesson('janta-13').notationRows, hasLength(20));
      expect(lesson('dhatu-8').notationRows, hasLength(20));
    });

    test('Devi Sthuthi retains lyric alignment and octave marks', () {
      final lesson = catalog.lessons.singleWhere((l) => l.id == 'devi-sthuthi');
      final copy = CarnaticLesson.fromJson(
        jsonDecode(jsonEncode(lesson)) as Map<String, dynamic>,
      );
      final score = copy.score!;
      expect(score.map((s) => (s.name, s.sangathi, s.rows.length)), [
        ('Pallavi', 1, 1),
        ('Pallavi', 2, 2),
        ('Samashti Charanam', null, 2),
        ('Samashti Charanam', 1, 2),
        ('Samashti Charanam', 2, 3),
      ]);
      expect(score.first.rows.single, hasLength(18));
      expect(score[1].rows.map((r) => r.length), [18, 18]);
      expect(score[2].lyrics, hasLength(5));
      expect(score.first.rows.first[9].notation, 'S N.');
      expect(score.first.rows.first[9].lyric, 'mo');
      expect(copy.sourceArohanam, 'SA RI3 MA1 PA DHA3 SA');

      final steps = copy.stepsFor(
        catalog.scaleFor(catalog.ragaNamed(copy.raga)!),
      );
      final start = steps.indexWhere((s) => s.lyric == 'mo');
      expect(steps[start].note, const SwaraNote(Swara.s));
      expect(steps[start + 1].note, const SwaraNote(Swara.n3, -1));
      expect(steps[start + 1].lyric, isNull);
      expect(steps.where((s) => s.note?.octave == 1), isNotEmpty);
      expect(steps.where((s) => s.note?.swara == Swara.r2), isNotEmpty);
      expect(steps.where((s) => s.note?.swara == Swara.d2), isNotEmpty);
    });

    test('Geetam row boundaries count swaras rather than lyric cells', () {
      final lesson = catalog.lessons.singleWhere((l) => l.id == 'devi-sthuthi');
      final firstRow = lesson.score!.first.rows.single;
      final secondRowIndex = firstRow
          .expand((cell) => tokenizeNotation(cell.notation))
          .length;
      final steps = lesson.stepsFor(
        catalog.scaleFor(catalog.ragaNamed(lesson.raga)!),
      );
      expect(secondRowIndex, greaterThan(firstRow.length));
      expect(
        steps.take(secondRowIndex + 1).indexed
            .where((entry) => entry.$2.startsRow)
            .map((entry) => entry.$1),
        [0, secondRowIndex],
      );
      expect(steps[secondRowIndex].lyric, 'sri');
    });

    test('karvai sustains the previous swara', () {
      final steps = CarnaticLesson(
        id: 't',
        group: 'g',
        title: 't',
        raga: 'Mayamalavagowla',
        flatNotation: tokenizeNotation(' S  , R '),
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
