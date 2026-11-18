import 'dart:math' as math;
import 'dart:typed_data';

/// One loop of PCM audio. The media player, not a Dart timer, drives the beat
/// so background timer throttling does not alter the tempo.
Uint8List metronomeWave(int bpm) {
  const sampleRate = 16000;
  const beats = 32;
  const clickSamples = 560;
  final framesPerBeat = sampleRate * 60 / bpm;
  // A mono PCM sample takes two bytes and the WAV header takes 44.
  final samples = ByteData(44 + (beats * framesPerBeat).round() * 2);
  void ascii(int start, String text) {
    for (var i = 0; i < text.length; i++) {
      samples.setUint8(start + i, text.codeUnitAt(i));
    }
  }

  const little = Endian.little;
  ascii(0, 'RIFF');
  samples.setUint32(4, samples.lengthInBytes - 8, little);
  ascii(8, 'WAVEfmt ');
  samples.setUint32(16, 16, little);
  samples.setUint16(20, 1, little);
  samples.setUint16(22, 1, little);
  samples.setUint32(24, sampleRate, little);
  samples.setUint32(28, sampleRate * 2, little);
  samples.setUint16(32, 2, little);
  samples.setUint16(34, 16, little);
  ascii(36, 'data');
  samples.setUint32(40, samples.lengthInBytes - 44, little);

  for (var i = 0; i < clickSamples; i++) {
    // A short rise and quick decay turn the sine into a click without a
    // hard amplitude jump at either end.
    final envelope = math.min(i / 16, 1) * math.pow(1 - i / clickSamples, 3);
    final sample =
        (10000 * envelope * math.sin(2 * math.pi * 1400 * i / sampleRate))
            .round();
    for (var beat = 0; beat < beats; beat++) {
      // Round the absolute sample position so fractional samples per beat
      // do not accumulate into tempo drift over the loop.
      final frame = (beat * framesPerBeat).round() + i;
      samples.setInt16(44 + frame * 2, sample, little);
    }
  }
  return samples.buffer.asUint8List();
}
