import 'package:flutter/foundation.dart';

import 'metronome_audio_native.dart'
    if (dart.library.js_interop) 'metronome_audio_web.dart'
    as platform;

/// Plays a looped beat independently of lesson playback and UI timers.
abstract class MetronomeAudio {
  factory MetronomeAudio() => platform.createMetronomeAudio();

  static bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> initialise() => platform.initialiseMetronomeAudio();

  /// Playback changes from the player, including system media controls.
  Stream<bool> get playing;

  /// Starts or replaces the audio loop at the given BPM.
  Future<void> play(int bpm, {required double volume});
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}
