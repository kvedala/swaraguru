import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

class ShrutiAudio {
  web.AudioContext? _context;
  web.GainNode? _master;
  final Map<double, (web.OscillatorNode, web.GainNode)> _voices = {};

  Future<void> start(Map<double, double> voices, double volume) async {
    final context = _context ??= web.AudioContext();
    // Resume within the Play gesture to satisfy browser autoplay policies.
    await context.resume().toDart;
    if (context.state != 'running') {
      throw StateError('Browser audio is suspended. Click Play to try again.');
    }
    _master ??= context.createGain()..connect(context.destination);
    update(voices, volume);
  }

  void update(Map<double, double> voices, double volume) {
    final context = _context;
    final master = _master;
    if (context == null || master == null) return;

    for (final frequency in _voices.keys.toList()) {
      if (!voices.containsKey(frequency)) {
        final (oscillator, gain) = _voices.remove(frequency)!;
        oscillator.stop();
        oscillator.disconnect();
        gain.disconnect();
      }
    }

    final totalGain = voices.values.fold(0.0, (sum, gain) => sum + gain);
    final normalization = math.max(1.0, totalGain);
    master.gain.setTargetAtTime(volume, context.currentTime, 0.015);
    for (final entry in voices.entries) {
      final voice = _voices.putIfAbsent(entry.key, () {
        final gain = context.createGain();
        gain.gain.value = 0;
        gain.connect(master);
        final oscillator = context.createOscillator();
        oscillator.type = 'sine';
        oscillator.frequency.value = entry.key;
        oscillator.connect(gain);
        oscillator.start();
        return (oscillator, gain);
      });
      voice.$2.gain.setTargetAtTime(
        entry.value / normalization,
        context.currentTime,
        0.015,
      );
    }
  }

  void stop() {
    for (final (oscillator, gain) in _voices.values) {
      oscillator.stop();
      oscillator.disconnect();
      gain.disconnect();
    }
    _voices.clear();
  }

  Future<void> dispose() async {
    stop();
    _master?.disconnect();
    _master = null;
    final context = _context;
    _context = null;
    if (context != null) await context.close().toDart;
  }
}
