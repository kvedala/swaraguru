import '../models/drone_settings.dart';
import '../models/instrument.dart';
import 'swara_audio_stub.dart'
    if (dart.library.js_interop) 'swara_audio_web.dart'
    as platform;

typedef PitchGlide = ({Duration offset, Duration duration, double frequencyHz});

/// Platform interface for the Shruti drone and synthesized swara playback.
///
/// Drones and lesson notes have independent lifecycles. The background click
/// uses a separate player because it does not need live synthesis.
abstract class SwaraAudio {
  factory SwaraAudio() => platform.createSwaraAudio();

  /// Whether this platform can produce sound.
  bool get isSupported;

  /// Unlocks audio output. Call from a user gesture (a button press) so that
  /// browser autoplay policies allow playback.
  Future<void> activate();

  Future<void> startDrone(DroneSound sound);

  /// Applies new drone settings while it is playing.
  void updateDrone(DroneSound sound);

  void stopDrone();

  /// Starts one voice. [glides] can change its pitch without a fresh attack.
  void playNote({
    required double frequencyHz,
    required Duration duration,
    required SwaraInstrument instrument,
    double volume = 0.8,
    List<PitchGlide> glides = const [],
  });

  /// Silences any swaras started by [playNote].
  void stopNotes();

  Future<void> dispose();
}
