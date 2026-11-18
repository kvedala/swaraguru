import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../models/pitch_evaluation.dart';
import 'yin_pitch_detector.dart';

/// A live stream of pitch readings, usually from the microphone. A `null`
/// reading means silence or an unpitched sound.
abstract class PitchSource {
  /// Amount of audio between consecutive readings, independent of delivery.
  Duration get readingInterval;

  /// Starts listening. Throws [PitchSourceException] when the input is
  /// unavailable or permission is denied.
  Future<Stream<PitchReading?>> start();

  Future<void> stop();

  Future<void> dispose();
}

/// A capture failure with a message suitable for displaying in the studio.
class PitchSourceException implements Exception {
  const PitchSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Captures 16-bit mono PCM with the `record` plugin and analyses it with
/// [YinPitchDetector]. Emits one reading per frame hop; audio stays on-device
/// and is never saved.
class MicrophonePitchSource implements PitchSource {
  MicrophonePitchSource({
    this.sampleRate = 44100,
    this.frameSize = 2048,
    this.hopSize = 1024,
  });

  final int sampleRate;
  final int frameSize;
  final int hopSize;

  late int _captureSampleRate = sampleRate;

  @override
  Duration get readingInterval => Duration(
    microseconds:
        (hopSize * Duration.microsecondsPerSecond / _captureSampleRate).round(),
  );

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _subscription;
  StreamController<PitchReading?>? _readings;

  @override
  Future<Stream<PitchReading?>> start() async {
    await stop();
    final recorder = _recorder ??= AudioRecorder();

    if (!await recorder.hasPermission()) {
      throw const PitchSourceException(
        'Microphone permission was denied. Allow microphone access to '
        'listen to your singing.',
      );
    }
    if (!await recorder.isEncoderSupported(AudioEncoder.pcm16bits)) {
      throw const PitchSourceException(
        'This device cannot stream raw microphone audio.',
      );
    }

    _captureSampleRate = sampleRate;
    var detector = YinPitchDetector(sampleRate: sampleRate.toDouble());
    // A platform can negotiate a different sample rate. Both frequency
    // estimates and elapsed audio time must use the rate it actually supplies.
    await recorder.setOnConfigChanged((config) {
      _captureSampleRate = config.sampleRate;
      detector = YinPitchDetector(sampleRate: config.sampleRate.toDouble());
    });

    final framer = Pcm16Framer(frameSize: frameSize, hopSize: hopSize);
    final readings = _readings = StreamController<PitchReading?>.broadcast();
    final Stream<Uint8List> audio;
    try {
      audio = await recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
    } catch (error) {
      await readings.close();
      _readings = null;
      throw PitchSourceException('Unable to open the microphone: $error');
    }

    _subscription = audio.listen(
      (chunk) {
        for (final frame in framer.add(chunk)) {
          if (readings.isClosed) return;
          readings.add(detector.detect(frame));
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!readings.isClosed) readings.addError(error, stack);
      },
    );
    return readings.stream;
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _readings?.close();
    _readings = null;
    final recorder = _recorder;
    if (recorder != null && await recorder.isRecording()) {
      await recorder.stop();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder?.dispose();
    _recorder = null;
  }
}
