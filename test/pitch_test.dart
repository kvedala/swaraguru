import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:swaraguru/models/models.dart';
import 'package:swaraguru/pitch/swara_identifier.dart';
import 'package:swaraguru/pitch/yin_pitch_detector.dart';

import 'support/fakes.dart';

const double sampleRate = 44100;

Float64List tone(double hz, {List<double> harmonics = const [1]}) =>
    Float64List.fromList([
      for (var i = 0; i < 2048; i++)
        0.3 *
            [
              for (var h = 0; h < harmonics.length; h++)
                harmonics[h] *
                    math.sin(2 * math.pi * hz * (h + 1) * i / sampleRate),
            ].reduce((a, b) => a + b),
    ]);

double shifted(double hz, double cents) => hz * math.pow(2, cents / 1200);

void main() {
  group('YinPitchDetector', () {
    final detector = YinPitchDetector(sampleRate: sampleRate);

    test('detects a pure sine', () {
      expect(detector.detect(tone(220))!.frequencyHz, closeTo(220, 0.5));
    });

    test('detects the fundamental of a harmonic-rich voice', () {
      final reading = detector.detect(
        tone(146.83, harmonics: [0.5, 1, 0.6, 0.3]),
      )!;
      expect(reading.frequencyHz, closeTo(146.83, 0.5));
      expect(reading.clarity, greaterThan(0.8));
    });

    test('ignores silence and noise', () {
      expect(detector.detect(Float64List(2048)), isNull);
      final random = math.Random(3);
      final noise = Float64List.fromList([
        for (var i = 0; i < 2048; i++) random.nextDouble() - 0.5,
      ]);
      expect(detector.detect(noise), isNull);
    });
  });

  test('Pcm16Framer reassembles samples split across chunks', () {
    final samples = [for (var i = 0; i < 12; i++) (i - 6) * 1000];
    final bytes = ByteData(samples.length * 2);
    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(i * 2, samples[i], Endian.little);
    }
    final data = bytes.buffer.asUint8List();
    final framer = Pcm16Framer(frameSize: 8, hopSize: 4);

    final frames = [
      ...framer.add(data.sublist(0, 7)),
      ...framer.add(data.sublist(7, 16)),
      ...framer.add(data.sublist(16)),
    ];
    expect(frames, hasLength(2));
    expect(frames[0], [for (final s in samples.take(8)) s / 32768]);
    expect(frames[1], [for (final s in samples.skip(4)) s / 32768]);
  });

  group('SwaraIdentifier', () {
    final catalog = loadTestCatalog();
    final saHz = kDefaultShruti.frequencyHz;
    final identifier = SwaraIdentifier(
      saHz: saHz,
      scale: catalog.scaleFor(catalog.defaultRaga),
    );

    test('names swaras in every octave', () {
      final tara = identifier.identify(saHz * 2);
      expect(tara.note, const SwaraNote(Swara.s, 1));
      expect(tara.centsOff, closeTo(0, 1e-9));

      final mandraPa = identifier.identify(saHz * 0.75);
      expect(mandraPa.note, const SwaraNote(Swara.p, -1));

      final sharpSa = identifier.identify(shifted(saHz, 12));
      expect(sharpSa.note, const SwaraNote(Swara.s));
      expect(sharpSa.centsOff, closeTo(12, 1e-9));
      expect(sharpSa.inRaga, isTrue);
    });

    test('flags swaras outside the raga', () {
      final r2 = identifier.identify(Swara.r2.frequencyFor(saHz));
      expect(r2.note.swara, Swara.r2);
      expect(r2.inRaga, isFalse);
    });

    test('grades sung swaras', () {
      const expected = SwaraNote(Swara.g3);
      final g3 = expected.frequencyFor(saHz);
      StepPitchEvaluation grade(double? hz) => identifier.evaluate(
        stepIndex: 0,
        expected: expected,
        sungFrequencyHz: hz,
      );

      expect(grade(shifted(g3, 20)).status, NoteMatchStatus.match);
      expect(grade(g3 / 2).status, NoteMatchStatus.match);
      expect(grade(g3 / 2).sung, const SwaraNote(Swara.g3, -1));

      final flat = grade(shifted(g3, -30));
      expect(flat.status, NoteMatchStatus.apasruti);
      expect(flat.message, 'Apasruti: -30 cents drift on G3');

      final wrong = grade(Swara.m1.frequencyFor(saHz));
      expect(wrong.status, NoteMatchStatus.wrongSwara);
      expect(wrong.message, 'Sang M1 (Shuddha Madhyamam) instead of G3');

      expect(grade(null).status, NoteMatchStatus.noVoice);
    });
  });

  test('stablePitch ignores the attack and takes the median', () {
    expect(stablePitch([]), isNull);
    expect(stablePitch([200]), 200);
    expect(stablePitch([400, 200, 220, 210]), 210);
    expect(stablePitch([500, 100, 400]), closeTo(200, 1e-9));
  });
}
