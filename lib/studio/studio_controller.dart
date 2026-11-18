import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/metronome_audio.dart';
import '../audio/swara_audio.dart';
import '../models/models.dart';
import '../pitch/pitch_source.dart';
import '../pitch/swara_identifier.dart';
import 'pitch_display.dart';

/// Where "Sing & Match" takes the student's pitch from.
enum CoachInput { microphone, simulatedStudent, simulatedVidwan }

/// User-facing names and descriptions for live and simulated coach inputs.
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

/// Whether the lesson grid is stopped, playing a reference, or grading vocals.
enum TransportMode { idle, reference, coaching }

/// Coordinates one studio session and owns its audio and microphone lifecycles.
///
/// The lesson transport advances the grid and grades notes. The Shruti drone
/// and audible metronome can run independently. Live listening and microphone
/// coaching share capture but use separate pitch windows.
class StudioController extends ChangeNotifier {
  static const minBpm = 60;
  static const maxBpm = 200;
  static const bpmIncrement = 10;

  StudioController({
    required this.catalog,
    this._audio,
    this._pitchSource,
    this._metronome,
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

  double get saHz => _shruti.frequencyHz;

  KaalamSpeed _kaalam = kKaalamOptions.first;
  KaalamSpeed get kaalam => _kaalam;

  int _bpm = minBpm;
  int get bpm => _bpm;

  MetronomeAudio? _metronome;
  StreamSubscription<bool>? _metronomeSubscription;
  Future<void>? _metronomeSync;
  bool _metronomeOn = false;
  bool get metronomeOn => _metronomeOn;
  bool get canUseMetronome => _metronome != null || MetronomeAudio.isSupported;

  void selectShruti(ShrutiPitch shruti) {
    if (_shruti == shruti) return;
    _shruti = shruti;
    _resetLivePitch();
    _stepFrequencies.clear();
    _notify();
    _syncDrone();
  }

  void selectKaalam(KaalamSpeed kaalam) {
    stopTransport();
    _kaalam = kaalam;
    _notify();
  }

  /// Updates the audible metronome immediately and the lesson at a step boundary.
  void setBpm(int bpm) {
    final bounded = bpm.clamp(minBpm, maxBpm);
    final next = (bounded / bpmIncrement).round() * bpmIncrement;
    if (next == _bpm) return;
    _bpm = next;
    if (_metronomeOn) _syncMetronome();
    _notify();
  }

  void toggleMetronome() {
    _metronomeOn = !_metronomeOn;
    _syncMetronome();
    _notify();
  }

  void _syncMetronome() {
    // Serialize starts, stops, and tempo changes so two actions cannot compete
    // for the same player while it is loading a loop.
    if (_metronomeSync != null) return;
    _metronomeSync = _applyMetronome().whenComplete(
      () => _metronomeSync = null,
    );
  }

  Future<void> _applyMetronome() async {
    try {
      final metronome = _metronome ??= MetronomeAudio();
      _metronomeSubscription ??= metronome.playing.listen(
        (playing) {
          // A tempo change can pause playback while replacing the loop. Outside
          // that transition, let system media controls update the UI.
          if (_disposed || _metronomeSync != null || playing == _metronomeOn) {
            return;
          }
          _metronomeOn = playing;
          _notify();
        },
        onError: (Object error, StackTrace stack) {
          _handleMetronomeError(error, stack);
          _syncMetronome();
        },
      );

      // Apply the latest request if BPM or play state changed during loading.
      int? requested;
      do {
        requested = _metronomeOn ? _bpm : null;
        if (requested == null) {
          await metronome.stop();
        } else {
          await metronome.play(requested, volume: practiceVolume);
        }
      } while (!_disposed && requested != (_metronomeOn ? _bpm : null));
    } catch (error, stack) {
      _handleMetronomeError(error, stack);
    }
  }

  void _handleMetronomeError(Object error, StackTrace stack) {
    debugPrint('Metronome playback failed: $error\n$stack');
    if (_disposed) return;
    _metronomeOn = false;
    _notify();
    onNotice?.call('Unable to play metronome: $error');
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
  bool get hasEvaluations => _evaluations.isNotEmpty;
  StepPitchEvaluation? evaluationAt(int index) => _evaluations[index];

  double _pitchTolerancePercent = SwaraIdentifier.defaultTolerancePercent;
  double get pitchTolerancePercent => _pitchTolerancePercent;

  /// Changes how new notes are graded without rewriting earlier results.
  void setPitchTolerancePercent(double percent) {
    final next = percent.clamp(0.0, SwaraIdentifier.maxTolerancePercent);
    if (next == _pitchTolerancePercent) return;
    _pitchTolerancePercent = next;
    _notify();
  }

  SwaraIdentifier get identifier => SwaraIdentifier(
    saHz: saHz,
    scale: _scale,
    tolerancePercent: pitchTolerancePercent,
  );

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
    _resetLivePitch();
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
      flatNotation: tokens,
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

  double get practiceVolume => _drone.volume;

  void setPracticeVolume(double volume) {
    final next = volume.clamp(0.0, 1.0);
    if (next == practiceVolume) return;
    updateDrone(_drone.copyWith(volume: next));
    unawaited(
      _metronome?.setVolume(next).catchError((Object error, StackTrace stack) {
        debugPrint('Metronome volume update failed: $error\n$stack');
        if (!_disposed) onNotice?.call('Unable to adjust metronome volume.');
      }),
    );
  }

  void setDroneInstrument(SwaraInstrument instrument) => updateDrone(
    _drone.mode == DroneMode.pureSingleNote
        ? _drone.copyWith(singleNoteInstrument: instrument)
        : _drone.copyWith(instrument: instrument),
  );

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
      // The window that just closed belongs to the previous cell. Grade it
      // before advancing the cursor, including the final cell in the lesson.
      if (mode == TransportMode.coaching &&
          _coachInput == CoachInput.microphone &&
          cursor > 0) {
        _finaliseMicrophoneStep(cursor - 1);
      }
      if (cursor >= _steps.length) {
        stopTransport();
        return;
      }
      // Reference notes are scheduled through following karvai cells (holds).
      // Keep those cells at the original tempo until that sustain ends.
      final nextStepIsKarvai =
          cursor < _steps.length && _steps[cursor].isKarvai;
      if (stepDuration != duration &&
          (mode != TransportMode.reference || !nextStepIsKarvai)) {
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
    // Invalidate reference and coaching starts still awaiting audio or permission.
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
    if (!_isListening) {
      pitchDisplay.value = PitchDisplay.reference(note, frequency);
    }
    if (step.isKarvai) return;

    var sustain = 1;
    while (index + sustain < _steps.length &&
        _steps[index + sustain].isKarvai) {
      sustain++;
    }
    try {
      audio.playNote(
        frequencyHz: frequency,
        // Leave a small gap so consecutive notes have distinct attacks.
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
    if (!_isListening) {
      pitchDisplay.value = PitchDisplay.reference(note, frequency);
    }
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
    // There are 1200 cents in an octave; adding an octave doubles frequency.
    final sungHz = expected.frequencyFor(saHz) * math.pow(2.0, offset / 1200.0);
    final id = identifier;
    _evaluations[index] = id.evaluate(
      stepIndex: index,
      expected: expected,
      sungFrequencyHz: sungHz,
    );
    if (!_isListening) {
      pitchDisplay.value = PitchDisplay.heard(id.identify(sungHz));
    }
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
  static const _livePitchHold = Duration(milliseconds: 250);
  SwaraNote? _candidate;
  Duration _candidateTime = Duration.zero;

  void _resetLivePitch() {
    _recentFrequencies.clear();
    _silentFrames = 0;
    _candidate = null;
    _candidateTime = Duration.zero;
    pitchDisplay.value = _isListening || microphoneActive
        ? PitchDisplay.listening
        : PitchDisplay.idle;
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      _isListening = false;
      _releaseMicrophoneIfIdle();
      _notify();
      return;
    }
    _isListening = true;
    _resetLivePitch();
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
      _resetLivePitch();
      _notify();
    }
  }

  Future<bool> _acquireMicrophone() {
    if (_micSubscription != null) return Future.value(true);
    // Listening and coaching may ask for permission at the same time.
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
      _resetLivePitch();
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
    _resetLivePitch();
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
      // Break the candidate's streak immediately but leave the last confirmed
      // label up through brief gaps, such as a breath between notes.
      _candidateTime = Duration.zero;
      if (++_silentFrames == 15) {
        _recentFrequencies.clear();
        pitchDisplay.value = PitchDisplay.listening;
      }
      return;
    }
    _silentFrames = 0;
    _recentFrequencies.add(reading.frequencyHz);
    if (_recentFrequencies.length > 5) _recentFrequencies.removeAt(0);
    // A short median rejects isolated detector jumps without averaging
    // two different swaras into a pitch the singer never held.
    final sorted = [..._recentFrequencies]..sort();
    final smoothed = sorted[sorted.length ~/ 2];
    final heard = identifier.identify(smoothed);
    if (_candidate != heard.note) {
      _candidate = heard.note;
      _candidateTime = Duration.zero;
    }
    // Audio time avoids counting a delayed batch as either one instant or a gap.
    _candidateTime += pitchSource.readingInterval;
    if (_candidateTime >= _livePitchHold) {
      pitchDisplay.value = PitchDisplay.heard(heard);
      _candidateTime = Duration.zero;
    }

    if (isCoaching &&
        _coachInput == CoachInput.microphone &&
        _activeStepIndex >= 0) {
      // Use the raw readings for grading so the display's confirmation delay
      // does not spill a previous note into the next lesson cell.
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
    unawaited(_metronomeSubscription?.cancel());
    final metronome = _metronome;
    if (metronome != null) {
      // An in-flight tempo change may still be using the player.
      _disposeResource(
        'Metronome',
        (_metronomeSync ?? Future<void>.value()).then(
          (_) => metronome.dispose(),
        ),
      );
    }
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
