import 'dart:math' as math;
import 'dart:typed_data';

import '../models/pitch_evaluation.dart';

/// Monophonic fundamental-frequency estimator using the YIN algorithm
/// (de Cheveigné & Kawahara, 2002). Estimates a repeating period from time-domain
/// samples rather than assuming the loudest harmonic is the sung pitch.
class YinPitchDetector {
  YinPitchDetector({
    required this.sampleRate,
    this.minFrequencyHz = 60,
    this.maxFrequencyHz = 1500,
    this.threshold = 0.15,
    this.silenceRms = 0.01,
  });

  final double sampleRate;
  final double minFrequencyHz;
  final double maxFrequencyHz;

  /// Upper bound on the normalised difference for a voiced frame.
  final double threshold;

  /// Frames quieter than this are treated as silence.
  final double silenceRms;

  Float64List? _cmnd;

  /// Returns the pitch of [frame], or `null` for silence or unpitched sound.
  /// The frame must hold at least two analysis windows of samples.
  PitchReading? detect(Float64List frame) {
    final window = frame.length ~/ 2;
    if (window < 8) return null;

    var energy = 0.0;
    for (final sample in frame) {
      energy += sample * sample;
    }
    final rms = math.sqrt(energy / frame.length);
    if (rms < silenceRms) return null;

    final minTau = math.max(2, (sampleRate / maxFrequencyHz).floor());
    final maxTau = math.min(window - 1, (sampleRate / minFrequencyHz).ceil());
    if (maxTau <= minTau + 1) return null;

    final cmnd = _cmnd?.length == maxTau + 2
        ? _cmnd!
        : _cmnd = Float64List(maxTau + 2);
    cmnd[0] = 1;
    var runningSum = 0.0;
    // A repeating waveform nearly matches itself when shifted by one period.
    // Divide each mismatch by the mean so far to avoid favoring tiny shifts.
    for (var tau = 1; tau <= maxTau + 1; tau++) {
      var diff = 0.0;
      for (var j = 0; j < window; j++) {
        final delta = frame[j] - frame[j + tau];
        diff += delta * delta;
      }
      runningSum += diff;
      cmnd[tau] = runningSum == 0 ? 1 : diff * tau / runningSum;
    }

    // Prefer the first clear dip: multiples of the period can also line up
    // but would report the note an octave (or more) too low.
    var tau = -1;
    for (var t = minTau; t <= maxTau; t++) {
      if (cmnd[t] < threshold) {
        while (t + 1 <= maxTau && cmnd[t + 1] < cmnd[t]) {
          t++;
        }
        tau = t;
        break;
      }
    }
    if (tau < 0) return null;

    // The true period usually lies between samples; interpolate the dip.
    final refinedTau = _parabolicPeak(cmnd, tau);
    final frequency = sampleRate / refinedTau;
    if (frequency < minFrequencyHz || frequency > maxFrequencyHz) return null;

    return PitchReading(
      frequencyHz: frequency,
      clarity: (1 - cmnd[tau]).clamp(0.0, 1.0),
      rms: rms,
    );
  }

  static double _parabolicPeak(Float64List values, int index) {
    if (index <= 0 || index >= values.length - 1) return index.toDouble();
    final left = values[index - 1];
    final centre = values[index];
    final right = values[index + 1];
    final denominator = left - 2 * centre + right;
    if (denominator == 0) return index.toDouble();
    return index + (left - right) / (2 * denominator);
  }
}

/// Splits little-endian 16-bit PCM into overlapping, normalized sample frames.
///
/// Input chunks need not align with sample or frame boundaries.
class Pcm16Framer {
  Pcm16Framer({this.frameSize = 2048, this.hopSize = 1024})
    : assert(hopSize > 0 && hopSize <= frameSize),
      _buffer = Float64List(frameSize);

  final int frameSize;
  final int hopSize;
  final Float64List _buffer;
  int _filled = 0;
  int? _pendingLowByte;

  /// Appends [bytes] and returns any complete frames, oldest first.
  List<Float64List> add(Uint8List bytes) {
    final frames = <Float64List>[];
    var index = 0;
    if (_pendingLowByte != null && bytes.isNotEmpty) {
      _push(_toSample(_pendingLowByte!, bytes[0]), frames);
      _pendingLowByte = null;
      index = 1;
    }
    for (; index + 1 < bytes.length; index += 2) {
      _push(_toSample(bytes[index], bytes[index + 1]), frames);
    }
    if (index < bytes.length) _pendingLowByte = bytes[index];
    return frames;
  }

  void reset() {
    _filled = 0;
    _pendingLowByte = null;
  }

  static double _toSample(int low, int high) {
    final value = (high << 8) | low;
    return (value >= 0x8000 ? value - 0x10000 : value) / 32768.0;
  }

  void _push(double sample, List<Float64List> frames) {
    _buffer[_filled++] = sample;
    if (_filled < frameSize) return;
    frames.add(Float64List.fromList(_buffer));
    // Keep the overlap so a new estimate can be made every hop instead of
    // waiting for an entirely fresh analysis window.
    _buffer.setRange(0, frameSize - hopSize, _buffer, hopSize);
    _filled = frameSize - hopSize;
  }
}
