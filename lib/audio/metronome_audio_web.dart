import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'metronome_audio.dart';
import 'metronome_wave.dart';

Future<void> initialiseMetronomeAudio() async {}

MetronomeAudio createMetronomeAudio() => _WebMetronome();

/// Browser media-element player that loops without a foreground Dart timer.
class _WebMetronome implements MetronomeAudio {
  _WebMetronome() {
    _events = [
      _player.onPlay.listen((_) => _playing.add(true)),
      _player.onPause.listen((_) => _playing.add(false)),
      _player.onError.listen((_) {
        _playing.addError(
          StateError(_player.error?.message ?? 'Playback failed.'),
        );
      }),
    ];
  }

  final _player = web.HTMLAudioElement()..loop = true;
  final _playing = StreamController<bool>.broadcast();
  late final List<StreamSubscription<web.Event>> _events;
  String? _source;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> play(int bpm, {required double volume}) async {
    _player.volume = volume;
    final blob = web.Blob(
      <JSAny>[metronomeWave(bpm).toJS].toJS,
      web.BlobPropertyBag(type: 'audio/wav'),
    );
    final next = web.URL.createObjectURL(blob);
    final previous = _source;
    // Keep the active blob URL available for playback, but free the old loop
    // when the user changes tempo.
    _source = next;
    _player.src = next;
    if (previous != null) web.URL.revokeObjectURL(previous);
    await _player.play().toDart;
  }

  @override
  Future<void> setVolume(double volume) async {
    _player.volume = volume;
  }

  @override
  Future<void> stop() async {
    _player.pause();
    _player.removeAttribute('src');
    _player.load();
    final source = _source;
    _source = null;
    if (source != null) web.URL.revokeObjectURL(source);
  }

  @override
  Future<void> dispose() async {
    for (final event in _events) {
      await event.cancel();
    }
    await stop();
    await _playing.close();
  }
}
