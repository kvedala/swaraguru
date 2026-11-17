import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/swara_audio.dart';
import '../models/models.dart';
import '../pitch/pitch_source.dart';
import '../pitch/swara_identifier.dart';
import 'pitch_display.dart';

/// Where "Sing & Match" takes the student's pitch from.
enum CoachInput { microphone, simulatedStudent, simulatedVidwan }

extension CoachInputInfo on CoachInput {
  String get label => switch (this) {
    CoachInput.microphone => 'Microphone',
    CoachInput.simulatedStudent => 'Simulated Student',
    CoachInput.simulatedVidwan => 'Simulated Vidwan',
  };

  String get description => switch (this) {
    CoachInput.microphone =>
      'Listens to your voice and compares each step with the expected swara.',
    CoachInput.simulatedStudent =>
      'Demo singer with realistic mistakes (R2 for R1, flat G3, D2 for D1).',
    CoachInput.simulatedVidwan => 'Demo singer with pitch-perfect intonation.',
  };
}

enum TransportMode { idle, reference, coaching }

/// Session state for the studio: Sa, raga, lesson, drone, playback and
/// pitch coaching. Widgets listen to it and call its actions.
class StudioController extends ChangeNotifier {
  StudioController({
    required this.catalog,
    this._audio,
    this._pitchSource,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    _lessons = catalog.lessons.isEmpty
        ? [CarnaticLesson.ragaScale(catalog.defaultRaga)]
        : List.of(catalog.lessons);
    _activeLesson = _lessons.first;
    _raga = catalog.ragaNamed(_activeLesson.raga) ?? catalog.defaultRaga;
    _scale = catalog.scaleFor(_raga);
    _steps = _activeLesson.stepsFor(_scale);
  }

  final CarnaticCatalog catalog;
  final math.Random _random;

  /// Receives user-facing messages such as playback errors.
  void Function(String message)? onNotice;

  SwaraAudio? _audio;
  SwaraAudio get audio => _audio ??= SwaraAudio();

  PitchSource? _pitchSource;
  PitchSource get pitchSource => _pitchSource ??= MicrophonePitchSource();

  bool _disposed = false;

  /// Live swara readout; updated many times per second while listening, so
  /// it is kept separate from [notifyListeners].
  final ValueNotifier<PitchDisplay> pitchDisplay = ValueNotifier(
    PitchDisplay.idle,
  );

  // ---------------------------------------------------------------------------
  // Sa, kaalam and laya
  // ---------------------------------------------------------------------------

  ShrutiPitch _shruti = kDefaultShruti;
  ShrutiPitch get shruti => _shruti;

  double _fineTuneCents = 0;
  double get fineTuneCents => _fineTuneCents;

  double get saHz =>
      _shruti.frequencyHz * math.pow(2.0, _fineTuneCents / 1200.0);

  KaalamSpeed _kaalam = kKaalamOptions.first;
  KaalamSpeed get kaalam => _kaalam;

  int _bpm = 68;
  int get bpm => _bpm;

  void selectShruti(ShrutiPitch shruti) {
    _shruti = shruti;
    _notify();
    _syncDrone();
  }

  void setFineTune(double cents) {
    _fineTuneCents = cents.clamp(-50.0, 50.0);
    _notify();
    _syncDrone();
  }

  void selectKaalam(KaalamSpeed kaalam) {
    stopTransport();
    _kaalam = kaalam;
    _notify();
  }

  /// A running transport picks up the new tempo at its next step.
  void setBpm(int bpm) {
    _bpm = bpm.clamp(40, 140);
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Raga and lessons
  // ---------------------------------------------------------------------------

  late Raga _raga;
  Raga get raga => _raga;

  late RagaScale _scale;
  RagaScale get scale => _scale;

  late List<CarnaticLesson> _lessons;
  List<CarnaticLesson> get lessons => List.unmodifiable(_lessons);

  late CarnaticLesson _activeLesson;
  CarnaticLesson get activeLesson => _activeLesson;

  late List<LessonStep> _steps;
  List<LessonStep> get steps => _steps;

  final Map<int, StepPitchEvaluation> _evaluations = {};
  Map<int, StepPitchEvaluation> get evaluations =>
      Map.unmodifiable(_evaluations);

  SwaraIdentifier get identifier => SwaraIdentifier(saHz: saHz, scale: _scale);

  /// Selecting a lesson also switches the session to the lesson's raga.
  void selectLesson(CarnaticLesson lesson) {
    stopTransport();
    _activeLesson = lesson;
    final raga = catalog.ragaNamed(lesson.raga);
    if (raga != null) _setRaga(raga);
    _steps = _activeLesson.stepsFor(_scale);
    _evaluations.clear();
    _notify();
  }

  /// Overrides the session raga; unnumbered letters in the lesson (such as
  /// `R` or `G`) are re-resolved to the swaras of [raga].
  void selectRaga(Raga raga) {
    if (raga == _raga) return;
    stopTransport();
    _setRaga(raga);
    _steps = _activeLesson.stepsFor(_scale);
    _evaluations.clear();
    _notify();
  }

  void _setRaga(Raga raga) {
    _raga = raga;
    _scale = catalog.scaleFor(raga);
  }

  /// Loads the arohanam and avarohanam of the session raga as a lesson.
  void practiceRagaScale() {
    final lesson = CarnaticLesson.ragaScale(_raga);
    final existing = _lessons.where((l) => l.id == lesson.id).firstOrNull;
    if (existing == null) _lessons.add(lesson);
    selectLesson(existing ?? lesson);
  }

  CarnaticLesson addCustomLesson({
    required String title,
    required Raga raga,
    required List<String> tokens,
  }) {
    final lesson = CarnaticLesson(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      group: 'Custom Song',
      title: title.trim().isEmpty ? 'Custom Varnam / Geetham' : title.trim(),
      raga: raga.name,
      description: 'User-entered custom swara notation.',
      swaras: tokens,
    );
    _lessons.add(lesson);
    selectLesson(lesson);
    return lesson;
  }

  // ---------------------------------------------------------------------------
  // Shruti drone
  // ---------------------------------------------------------------------------

  DroneSettings _drone = DroneSettings();
  DroneSettings get drone => _drone;

  bool _dronePlaying = false;
  bool get dronePlaying => _dronePlaying;
  bool _droneStarting = false;

  DroneSound get _droneSound => _drone.soundFor(saHz);

  /// Traditional tampura tuning for the session raga.
  DronePreset get suggestedDronePreset {
    if (_scale.containsPosition(Swara.p.position)) return DronePreset.pa;
    if (_scale.containsPosition(Swara.m1.position)) return DronePreset.ma;
    if (_scale.containsPosition(Swara.n3.position)) return DronePreset.ni;
    return DronePreset.saOnly;
  }

  Future<void> toggleDrone() async {
    if (_droneStarting) return;
    if (_dronePlaying) {
      audio.stopDrone();
      _dronePlaying = false;
      _notify();
      return;
    }
    _droneStarting = true;
    try {
      await audio.startDrone(_droneSound);
      if (_disposed) {
        audio.stopDrone();
        return;
      }
      // Settings may have changed while the audio was starting.
      audio.updateDrone(_droneSound);
      _dronePlaying = true;
      _notify();
    } catch (error, stack) {
      _handleDroneError(error, stack);
    } finally {
      _droneStarting = false;
    }
  }

  void updateDrone(DroneSettings settings) {
    _drone = settings;
    _notify();
    _syncDrone();
  }

  void setDroneMode(DroneMode mode) => updateDrone(_drone.copyWith(mode: mode));

  void setPureChannel(DroneChannel channel) =>
      updateDrone(_drone.copyWith(pureChannel: channel));

  void setChannelLevel(DroneChannel channel, double level) =>
      updateDrone(_drone.withLevel(channel, level));

  void setDroneVolume(double volume) =>
      updateDrone(_drone.copyWith(volume: volume));

  void setDroneInstrument(SwaraInstrument instrument) =>
      updateDrone(_drone.copyWith(instrument: instrument));

  void applyDronePreset(DronePreset preset) => updateDrone(
    _drone.copyWith(mode: DroneMode.multiNoteChord, mix: preset.mix),
  );

  void _syncDrone() {
    if (!_dronePlaying) return;
    try {
      audio.updateDrone(_droneSound);
    } catch (error, stack) {
      _handleDroneError(error, stack);
    }
  }

  void _handleDroneError(Object error, StackTrace stack) {
    try {
      audio.stopDrone();
    } catch (_) {
      // The drone is already unusable; report the original error.
    }
    debugPrint('Shruti playback failed: $error\n$stack');
    if (_disposed) return;
    _dronePlaying = false;
    _notify();
    onNotice?.call('Unable to play Shruti: $error');
  }

  // ---------------------------------------------------------------------------
  // Varisai playback and pitch coaching
  // ---------------------------------------------------------------------------

  SwaraInstrument _noteInstrument = SwaraInstrument.harmonium;
  SwaraInstrument get noteInstrument => _noteInstrument;

  CoachInput _coachInput = CoachInput.microphone;
  CoachInput get coachInput => _coachInput;

  TransportMode _mode = TransportMode.idle;
  bool get isPlayingReference => _mode == TransportMode.reference;
  bool get isCoaching => _mode == TransportMode.coaching;
  bool get isTransportRunning => _mode != TransportMode.idle;

  int _activeStepIndex = -1;
  int get activeStepIndex => _activeStepIndex;

  int _activeBeat = 1;
  int get activeBeat => _activeBeat;

  Timer? _transportTimer;
  int _transportGeneration = 0;

  /// Generation of a microphone coaching request still waiting for capture.
  int? _pendingMicCoaching;
  bool get _micCoachingPending => _pendingMicCoaching == _transportGeneration;

  bool _unsupportedAudioNoticeShown = false;
  final List<double> _stepFrequencies = [];

  Duration get stepDuration =>
      Duration(microseconds: (60e6 / _bpm / _kaalam.swarasPerBeat).round());

  void setNoteInstrument(SwaraInstrument instrument) {
    _noteInstrument = instrument;
    _notify();
  }

  void setCoachInput(CoachInput input) {
    if (input == _coachInput) return;
    if (isCoaching || _micCoachingPending) stopTransport();
    _coachInput = input;
    _notify();
  }

  /// Plays the lesson on [noteInstrument] while stepping through the grid.
  Future<void> playReference() async {
    stopTransport();
    final generation = _transportGeneration;
    if (await _activateAudio() && generation == _transportGeneration) {
      _startTransport(TransportMode.reference);
    }
  }

  /// Steps through the lesson and evaluates the singer at each swara.
  Future<void> startCoaching() async {
    stopTransport();
    final generation = _transportGeneration;
    _evaluations.clear();
    _notify();
    if (_coachInput == CoachInput.microphone) {
      _pendingMicCoaching = generation;
      final acquired = await _acquireMicrophone();
      if (_pendingMicCoaching == generation) _pendingMicCoaching = null;
      if (!acquired) return;
    }
    if (_disposed) return;
    if (generation != _transportGeneration) {
      _releaseMicrophoneIfIdle();
      return;
    }
    _startTransport(TransportMode.coaching);
  }

  Future<bool> _activateAudio() async {
    try {
      await audio.activate();
    } on UnsupportedError catch (error) {
      if (!_unsupportedAudioNoticeShown) {
        _unsupportedAudioNoticeShown = true;
        onNotice?.call('${error.message} Showing visual playback only.');
      }
    } catch (error) {
      onNotice?.call('Unable to start instrument audio: $error');
    }
    return !_disposed;
  }

  void _startTransport(TransportMode mode) {
    _mode = mode;
    _stepFrequencies.clear();
    final swarasPerBeat = _kaalam.swarasPerBeat;
    var duration = stepDuration;
    var cursor = 0;

    void tick() {
      if (_disposed) return;
      if (mode == TransportMode.coaching &&
          _coachInput == CoachInput.microphone &&
          cursor > 0) {
        _finaliseMicrophoneStep(cursor - 1);
      }
      if (cursor >= _steps.length) {
        stopTransport();
        return;
      }
      // Rescheduling here rather than in setBpm keeps the transport moving
      // while the tempo slider is dragged.
      if (stepDuration != duration) {
        duration = stepDuration;
        _transportTimer?.cancel();
        _transportTimer = Timer.periodic(duration, (_) => tick());
      }
      _activeStepIndex = cursor;
      _activeBeat = ((cursor ~/ swarasPerBeat) % 8) + 1;
      if (mode == TransportMode.reference) {
        _playStep(cursor, duration);
      } else if (_coachInput != CoachInput.microphone) {
        _simulateStep(cursor);
      }
      HapticFeedback.selectionClick();
      cursor++;
      _notify();
    }

    tick();
    _transportTimer = Timer.periodic(duration, (_) => tick());
  }

  void stopTransport() {
    _transportGeneration++;
    _transportTimer?.cancel();
    _transportTimer = null;
    final changed = _mode != TransportMode.idle || _activeStepIndex != -1;
    if (_mode == TransportMode.reference) {
      try {
        _audio?.stopNotes();
      } catch (error) {
        debugPrint('Unable to stop notes: $error');
      }
    }
    _mode = TransportMode.idle;
    _activeStepIndex = -1;
    _stepFrequencies.clear();
    _releaseMicrophoneIfIdle();
    if (changed) _notify();
  }

  void _playStep(int index, Duration duration) {
    final step = _steps[index];
    final note = step.note;
    if (note == null) return;
    final frequency = note.frequencyFor(saHz);
    pitchDisplay.value = PitchDisplay.reference(note, frequency);
    if (step.isKarvai) return;

    var sustain = 1;
    while (index + sustain < _steps.length &&
        _steps[index + sustain].isKarvai) {
      sustain++;
    }
    try {
      audio.playNote(
        frequencyHz: frequency,
        duration: duration * (sustain * 0.94),
        instrument: _noteInstrument,
      );
    } catch (error) {
      debugPrint('Unable to play swara: $error');
    }
  }

  /// Highlights a swara cell and, when idle, plays it once.
  Future<void> previewStep(int index) async {
    if (index < 0 || index >= _steps.length) return;
    final note = _steps[index].note;
    if (note == null) return;
    final frequency = note.frequencyFor(saHz);
    _activeStepIndex = index;
    pitchDisplay.value = PitchDisplay.reference(note, frequency);
    _notify();
    if (isTransportRunning || !audio.isSupported) return;
    try {
      await audio.activate();
      audio.playNote(
        frequencyHz: frequency,
        duration: const Duration(milliseconds: 900),
        instrument: _noteInstrument,
      );
    } catch (error) {
      debugPrint('Unable to preview swara: $error');
    }
  }

  int _simulatedCentOffset(int index, SwaraNote expected) {
    if (_coachInput == CoachInput.simulatedVidwan) {
      return _random.nextInt(10) - 5;
    }
    return switch (expected.swara.letter) {
      SwaraLetter.r when index % 5 == 1 => 104,
      SwaraLetter.g when index % 6 == 2 => -36,
      SwaraLetter.d when index % 4 == 1 => 96,
      _ => _random.nextInt(18) - 9,
    };
  }

  void _simulateStep(int index) {
    final expected = _steps[index].note;
    if (expected == null) return;
    final offset = _simulatedCentOffset(index, expected);
    final sungHz = expected.frequencyFor(saHz) * math.pow(2.0, offset / 1200.0);
    final id = identifier;
    _evaluations[index] = id.evaluate(
      stepIndex: index,
      expected: expected,
      sungFrequencyHz: sungHz,
    );
    pitchDisplay.value = PitchDisplay.heard(id.identify(sungHz));
  }

  void _finaliseMicrophoneStep(int index) {
    final frequencies = List.of(_stepFrequencies);
    _stepFrequencies.clear();
    final expected = _steps[index].note;
    if (expected == null) return;
    _evaluations[index] = identifier.evaluate(
      stepIndex: index,
      expected: expected,
      sungFrequencyHz: stablePitch(frequencies),
    );
  }

  // ---------------------------------------------------------------------------
  // Microphone listening
  // ---------------------------------------------------------------------------

  bool _isListening = false;

  /// Whether the live note identifier is on.
  bool get isListening => _isListening;

  bool get microphoneActive => _micSubscription != null;

  StreamSubscription<PitchReading?>? _micSubscription;
  Future<bool>? _micStarting;
  final List<double> _recentFrequencies = [];
  int _silentFrames = 0;

  Future<void> toggleListening() async {
    if (_isListening) {
      _isListening = false;
      _releaseMicrophoneIfIdle();
      pitchDisplay.value = PitchDisplay.idle;
      _notify();
      return;
    }
    _isListening = true;
    _notify();
    final acquired = await _acquireMicrophone();
    if (_disposed) return;
    if (!_isListening) {
      // Listening was switched off while the microphone was starting.
      _releaseMicrophoneIfIdle();
      return;
    }
    if (acquired) {
      if (pitchDisplay.value.source != PitchDisplaySource.voice) {
        pitchDisplay.value = PitchDisplay.listening;
      }
    } else {
      _isListening = false;
      _notify();
    }
  }

  Future<bool> _acquireMicrophone() {
    if (_micSubscription != null) return Future.value(true);
    return _micStarting ??= _startMicrophone().whenComplete(
      () => _micStarting = null,
    );
  }

  Future<bool> _startMicrophone() async {
    try {
      final readings = await pitchSource.start();
      if (_disposed) {
        await pitchSource.stop();
        return false;
      }
      _recentFrequencies.clear();
      _silentFrames = 0;
      _micSubscription = readings.listen(
        _onReading,
        onError: (Object error) {
          onNotice?.call('Microphone error: $error');
          _isListening = false;
          if (isCoaching && _coachInput == CoachInput.microphone) {
            stopTransport();
          }
          _releaseMicrophoneIfIdle(force: true);
          _notify();
        },
      );
      _notify();
      return true;
    } catch (error) {
      if (!_disposed) onNotice?.call('Microphone unavailable: $error');
      return false;
    }
  }

  void _releaseMicrophoneIfIdle({bool force = false}) {
    final coachingWithMic =
        (isCoaching && _coachInput == CoachInput.microphone) ||
        _micCoachingPending;
    if (!force && (_isListening || coachingWithMic)) return;
    final subscription = _micSubscription;
    if (subscription == null) return;
    _micSubscription = null;
    unawaited(subscription.cancel());
    unawaited(
      pitchSource.stop().catchError((Object error) {
        debugPrint('Unable to stop microphone: $error');
      }),
    );
  }

  void _onReading(PitchReading? reading) {
    if (_disposed) return;
    if (reading == null) {
      if (++_silentFrames == 8) {
        _recentFrequencies.clear();
        pitchDisplay.value = PitchDisplay.listening;
      }
      return;
    }
    _silentFrames = 0;
    _recentFrequencies.add(reading.frequencyHz);
    if (_recentFrequencies.length > 5) _recentFrequencies.removeAt(0);
    final sorted = [..._recentFrequencies]..sort();
    final smoothed = sorted[sorted.length ~/ 2];
    pitchDisplay.value = PitchDisplay.heard(identifier.identify(smoothed));

    if (isCoaching &&
        _coachInput == CoachInput.microphone &&
        _activeStepIndex >= 0) {
      _stepFrequencies.add(reading.frequencyHz);
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _transportTimer?.cancel();
    unawaited(_micSubscription?.cancel());
    _micSubscription = null;
    _disposeResource('Swara audio', _audio?.dispose());
    _disposeResource('Microphone', _pitchSource?.dispose());
    pitchDisplay.dispose();
    super.dispose();
  }

  static void _disposeResource(String library, Future<void>? disposal) {
    if (disposal == null) return;
    unawaited(
      disposal.catchError((Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack, library: library),
        );
      }),
    );
  }
}
