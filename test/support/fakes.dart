import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swaraguru/app.dart';
import 'package:swaraguru/audio/swara_audio.dart';
import 'package:swaraguru/models/models.dart';
import 'package:swaraguru/pitch/pitch_source.dart';

/// Reads the bundled data assets directly so tests need no async loading.
CarnaticCatalog loadTestCatalog() {
  Map<String, dynamic> read(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return CarnaticCatalog.fromJson({
    ...read(CarnaticCatalog.ragasAsset),
    ...read(CarnaticCatalog.lessonsAsset),
  });
}

typedef PlayedNote = ({
  double frequencyHz,
  Duration duration,
  SwaraInstrument instrument,
});

class FakeSwaraAudio implements SwaraAudio {
  bool supported = true;
  bool failToStart = false;
  Object? activateError;
  bool activated = false;
  bool droneStopped = false;
  bool disposed = false;
  int stopNotesCalls = 0;
  DroneSound? drone;
  final List<PlayedNote> notes = [];

  @override
  bool get isSupported => supported;

  @override
  Future<void> activate() async {
    final error = activateError;
    if (error != null) throw error;
    activated = true;
  }

  @override
  Future<void> startDrone(DroneSound sound) async {
    if (failToStart) throw StateError('Audio blocked');
    droneStopped = false;
    drone = sound;
  }

  @override
  void updateDrone(DroneSound sound) => drone = sound;

  @override
  void stopDrone() => droneStopped = true;

  @override
  void playNote({
    required double frequencyHz,
    required Duration duration,
    required SwaraInstrument instrument,
    double volume = 0.8,
  }) => notes.add((
    frequencyHz: frequencyHz,
    duration: duration,
    instrument: instrument,
  ));

  @override
  void stopNotes() => stopNotesCalls++;

  @override
  Future<void> dispose() async => disposed = true;
}

class FakePitchSource implements PitchSource {
  Object? failWith;
  int starts = 0;
  int stops = 0;
  bool disposed = false;
  StreamController<PitchReading?>? _readings;

  bool get isActive => _readings != null;

  @override
  Future<Stream<PitchReading?>> start() async {
    final error = failWith;
    if (error != null) throw error;
    starts++;
    // Synchronous delivery so a single pump renders each emitted reading.
    _readings = StreamController<PitchReading?>.broadcast(sync: true);
    return _readings!.stream;
  }

  /// Sends a voiced reading, or silence when [frequencyHz] is `null`.
  void emit(double? frequencyHz) => _readings?.add(
    frequencyHz == null
        ? null
        : PitchReading(frequencyHz: frequencyHz, clarity: 0.95, rms: 0.1),
  );

  @override
  Future<void> stop() async {
    stops++;
    final readings = _readings;
    _readings = null;
    await readings?.close();
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await stop();
  }
}

/// Serves a preloaded README and falls back to [rootBundle] for other keys.
class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle(this.readme);

  final String readme;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == 'README.md'
      ? Future.value(readme)
      : rootBundle.loadString(key, cache: cache);
}

Future<void> pumpStudio(
  WidgetTester tester, {
  FakeSwaraAudio? audio,
  FakePitchSource? pitchSource,
  Size size = const Size(1600, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: TestAssetBundle(File('README.md').readAsStringSync()),
      child: SwaraGuruApp(
        catalog: loadTestCatalog(),
        audio: audio ?? FakeSwaraAudio(),
        pitchSource: pitchSource ?? FakePitchSource(),
      ),
    ),
  );
}

Matcher droneVoices(Map<double, double> expected) =>
    predicate<DroneSound?>((sound) {
      if (sound == null || sound.voices.length != expected.length) return false;
      final entries = expected.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final voice = sound.voices[i];
        if ((voice.frequencyHz - entries[i].key).abs() > 1e-6 ||
            (voice.gain - entries[i].value).abs() > 1e-9) {
          return false;
        }
      }
      return true;
    }, 'drone voices $expected');
