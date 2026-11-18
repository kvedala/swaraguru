import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:swaraguru/audio/metronome_wave.dart';

void main() {
  test('PCM loop contains 32 evenly spaced clicks at supported tempos', () {
    for (final bpm in [60, 130, 200]) {
      final wav = ByteData.sublistView(metronomeWave(bpm));
      final rate = wav.getUint32(24, Endian.little);
      final dataLength = wav.getUint32(40, Endian.little);
      expect(dataLength, wav.lengthInBytes - 44);
      final frames = dataLength ~/ 2;
      final starts = <int>[];
      var lastSignal = -rate;
      for (var frame = 0; frame < frames; frame++) {
        if (wav.getInt16(44 + 2 * frame, Endian.little).abs() < 100) continue;
        if (frame - lastSignal > rate ~/ 10) starts.add(frame);
        lastSignal = frame;
      }
      expect(starts, hasLength(32));
      for (var beat = 0; beat < starts.length; beat++) {
        final next = beat + 1 < starts.length
            ? starts[beat + 1]
            : starts[0] + frames;
        expect((next - starts[beat]) / rate, closeTo(60 / bpm, 1 / rate));
      }
    }
  });
}
