import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'metronome_audio.dart';
import 'metronome_wave.dart';

Future<void> initialiseMetronomeAudio() => JustAudioBackground.init(
  androidNotificationChannelId: 'com.swaraguru.swaraguru.metronome',
  androidNotificationChannelName: 'SwaraGuru Metronome',
);

MetronomeAudio createMetronomeAudio() => _NativeMetronome();

/// Android and iOS media player with background and system playback controls.
///
/// Keeps one temporary WAV per used tempo for the player's lifetime.
class _NativeMetronome implements MetronomeAudio {
  _NativeMetronome() {
    _state = _player.playingStream.listen(_playing.add);
    _errors = _player.errorStream.listen(_playing.addError);
  }

  final _player = AudioPlayer();
  final _playing = StreamController<bool>.broadcast();
  late final StreamSubscription<bool> _state;
  late final StreamSubscription<PlayerException> _errors;
  Directory? _cache;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> play(int bpm, {required double volume}) async {
    await setVolume(volume);
    final cache = _cache ??= await Directory.systemTemp.createTemp(
      'swaraguru-metronome-',
    );
    final file = File.fromUri(cache.uri.resolve('$bpm.wav'));
    if (!await file.exists()) await file.writeAsBytes(metronomeWave(bpm));
    await _player.pause();
    await _player.setAudioSource(
      AudioSource.uri(
        file.uri,
        tag: MediaItem(
          id: 'metronome-$bpm',
          title: 'SwaraGuru Metronome • $bpm BPM',
        ),
      ),
    );
    await _player.setLoopMode(LoopMode.one);
    // play() completes only when playback ends, pauses, or stops.
    unawaited(_player.play().catchError(_playing.addError));
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> stop() async {
    await _player.pause();
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _state.cancel();
    await _errors.cancel();
    await _player.dispose();
    await _cache?.delete(recursive: true);
    await _playing.close();
  }
}
