import '../models/drone_settings.dart';
import '../models/instrument.dart';
import 'swara_audio.dart';

SwaraAudio createSwaraAudio() => _UnsupportedSwaraAudio();

class _UnsupportedSwaraAudio implements SwaraAudio {
  static const _message =
      'Instrument audio is currently available in the web app only.';

  @override
  bool get isSupported => false;

  @override
  Future<void> activate() async => throw UnsupportedError(_message);

  @override
  Future<void> startDrone(DroneSound sound) async =>
      throw UnsupportedError(_message);

  @override
  void updateDrone(DroneSound sound) {}

  @override
  void stopDrone() {}

  @override
  void playNote({
    required double frequencyHz,
    required Duration duration,
    required SwaraInstrument instrument,
    double volume = 0.8,
  }) {}

  @override
  void stopNotes() {}

  @override
  Future<void> dispose() async {}
}
