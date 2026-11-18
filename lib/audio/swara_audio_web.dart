import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import '../models/drone_settings.dart';
import '../models/instrument.dart';
import 'instrument_timbre.dart';
import 'swara_audio.dart';

SwaraAudio createSwaraAudio() => WebSwaraAudio();

/// Web Audio synthesiser. Each instrument is an additive [web.PeriodicWave]
/// shaped by a low-pass filter and an amplitude envelope; plucked drones are
/// re-struck by a look-ahead scheduler, harmonium drones are sustained.
class WebSwaraAudio implements SwaraAudio {
  static const _schedulerTick = Duration(milliseconds: 60);
  static const _lookaheadSeconds = 0.3;
  static const _pluckGapSeconds = 0.6;
  static const _cycleRestSeconds = 0.6;
  static const _fadeSeconds = 0.06;

  web.AudioContext? _context;
  web.GainNode? _droneBus;
  web.GainNode? _notesBus;
  final Map<SwaraInstrument, web.PeriodicWave> _waves = {};

  DroneSound? _drone;
  Timer? _pluckTimer;
  double _nextPluckTime = 0;
  int _pluckIndex = 0;
  final Map<double, _Voice> _sustainedDrone = {};
  final List<_Voice> _droneStrikes = [];
  final List<_Voice> _notes = [];

  @override
  bool get isSupported => true;

  @override
  Future<void> activate() async {
    final context = _context ??= _createContext();
    await context.resume().toDart;
    if (context.state != 'running') {
      throw StateError('Browser audio is suspended. Click Play to try again.');
    }
  }

  web.AudioContext _createContext() {
    final context = web.AudioContext();
    final compressor = context.createDynamicsCompressor();
    compressor.threshold.value = -14;
    compressor.knee.value = 8;
    compressor.ratio.value = 4;
    compressor.connect(context.destination);
    final master = context.createGain()..gain.value = 0.9;
    master.connect(compressor);
    _droneBus = context.createGain()..connect(master);
    _notesBus = context.createGain()..connect(master);
    return context;
  }

  @override
  Future<void> startDrone(DroneSound sound) async {
    await activate();
    _stopDroneVoices(_fadeSeconds);
    _drone = sound;
    _droneBus!.gain.value = sound.volume;
    _beginDrone(sound);
  }

  @override
  void updateDrone(DroneSound sound) {
    final previous = _drone;
    final context = _context;
    if (previous == null || context == null) return;
    final voicesChanged = !_sameDroneVoices(previous.voices, sound.voices);
    _drone = sound;
    _droneBus!.gain.setTargetAtTime(sound.volume, context.currentTime, 0.03);
    final plucked = sound.instrument.timbre.isPlucked;
    if (previous.instrument != sound.instrument || (plucked && voicesChanged)) {
      _stopDroneVoices(_fadeSeconds);
      _beginDrone(sound);
    } else if (voicesChanged) {
      _syncSustainedDrone(sound);
    }
    // Master volume changes leave the individual voice envelopes alone.
  }

  static bool _sameDroneVoices(List<DroneVoice> a, List<DroneVoice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void stopDrone() {
    _drone = null;
    _stopDroneVoices(_fadeSeconds);
  }

  void _beginDrone(DroneSound sound) {
    if (sound.instrument.timbre.isPlucked) {
      _pluckIndex = 0;
      _nextPluckTime = _context!.currentTime + 0.05;
      _schedulePlucks();
      _pluckTimer = Timer.periodic(_schedulerTick, (_) => _schedulePlucks());
    } else {
      _syncSustainedDrone(sound);
    }
  }

  void _stopDroneVoices(double fadeSeconds) {
    _pluckTimer?.cancel();
    _pluckTimer = null;
    final context = _context;
    if (context == null) return;
    final now = context.currentTime;
    for (final voice in [..._droneStrikes, ..._sustainedDrone.values]) {
      voice.release(now, fadeSeconds);
    }
    _droneStrikes.clear();
    _sustainedDrone.clear();
  }

  /// Lowest string first, then the rest from the top down, like the
  /// traditional P–Ṡ–Ṡ–S tampura stroke.
  static List<DroneVoice> _pluckOrder(List<DroneVoice> voices) {
    final ascending = [...voices]
      ..sort((a, b) => a.frequencyHz.compareTo(b.frequencyHz));
    if (ascending.length < 2) return ascending;
    return [ascending.first, ...ascending.skip(1).toList().reversed];
  }

  void _schedulePlucks() {
    final context = _context;
    final sound = _drone;
    if (context == null || sound == null) return;
    final now = context.currentTime;
    _prune(_droneStrikes, now);

    final order = _pluckOrder(sound.voices);
    // Background tabs throttle timers; skip missed plucks instead of
    // bunching them up.
    if (_nextPluckTime < now) _nextPluckTime = now + 0.02;
    if (order.isEmpty) return;

    final timbre = sound.instrument.timbre;
    // Dart wakes the scheduler; Web Audio starts each oscillator at the
    // requested audio-clock time, not at the moment the Dart timer fires.
    while (_nextPluckTime < now + _lookaheadSeconds) {
      if (_pluckIndex >= order.length) _pluckIndex = 0;
      final voice = order[_pluckIndex++];
      final strike = _createVoice(
        frequencyHz: voice.frequencyHz,
        instrument: sound.instrument,
        when: _nextPluckTime,
        gain: voice.gain * 0.8,
        destination: _droneBus!,
      );
      strike.envelope.gain.setTargetAtTime(
        0,
        _nextPluckTime + timbre.attackSeconds,
        timbre.decaySeconds!,
      );
      strike.stopAt(_nextPluckTime + timbre.ringSeconds);
      _droneStrikes.add(strike);
      _nextPluckTime +=
          _pluckGapSeconds +
          (_pluckIndex >= order.length ? _cycleRestSeconds : 0);
    }
  }

  void _syncSustainedDrone(DroneSound sound) {
    final context = _context!;
    final now = context.currentTime;
    final timbre = sound.instrument.timbre;
    final total = sound.voices.fold(0.0, (sum, voice) => sum + voice.gain);
    final normalisation = math.max(1.0, total);
    final wanted = {
      for (final voice in sound.voices)
        voice.frequencyHz: voice.gain / normalisation,
    };

    for (final frequency in _sustainedDrone.keys.toList()) {
      if (!wanted.containsKey(frequency)) {
        _sustainedDrone.remove(frequency)!.release(now, timbre.releaseSeconds);
      }
    }
    for (final MapEntry(key: frequency, value: gain) in wanted.entries) {
      final existing = _sustainedDrone[frequency];
      if (existing == null) {
        _sustainedDrone[frequency] = _createVoice(
          frequencyHz: frequency,
          instrument: sound.instrument,
          when: now,
          gain: gain,
          destination: _droneBus!,
        );
      } else {
        existing.envelope.gain.setTargetAtTime(
          gain * existing.peakScale,
          now,
          0.03,
        );
      }
    }
  }

  @override
  void playNote({
    required double frequencyHz,
    required Duration duration,
    required SwaraInstrument instrument,
    double volume = 0.8,
    List<PitchGlide> glides = const [],
  }) {
    final context = _context;
    final bus = _notesBus;
    if (context == null || bus == null || context.state != 'running') return;
    final now = context.currentTime;
    _prune(_notes, now);

    final timbre = instrument.timbre;
    final start = now + 0.005;
    final end =
        start + duration.inMicroseconds / Duration.microsecondsPerSecond;
    final note = _createVoice(
      frequencyHz: frequencyHz,
      instrument: instrument,
      when: start,
      gain: volume,
      destination: bus,
    );
    final gain = note.envelope.gain;
    for (final oscillator in note.oscillators) {
      final pitch = oscillator.frequency;
      var previousHz = frequencyHz;
      for (final glide in glides) {
        final at = start + glide.offset.inMicroseconds / Duration.microsecondsPerSecond;
        pitch.setValueAtTime(previousHz, at);
        pitch.exponentialRampToValueAtTime(
          glide.frequencyHz,
          at + glide.duration.inMicroseconds / Duration.microsecondsPerSecond,
        );
        previousHz = glide.frequencyHz;
      }
    }
    if (timbre.isPlucked) {
      gain.setTargetAtTime(
        0,
        start + timbre.attackSeconds,
        timbre.decaySeconds!,
      );
    }
    gain.setTargetAtTime(0, end, timbre.releaseSeconds / 3);
    note.stopAt(end + timbre.releaseSeconds * 2);
    _notes.add(note);
  }

  @override
  void stopNotes() {
    final context = _context;
    if (context == null) return;
    for (final note in _notes) {
      note.release(context.currentTime, _fadeSeconds);
    }
    _notes.clear();
  }

  _Voice _createVoice({
    required double frequencyHz,
    required SwaraInstrument instrument,
    required double when,
    required double gain,
    required web.AudioNode destination,
  }) {
    final context = _context!;
    final timbre = instrument.timbre;
    final wave = _waves[instrument] ??= _periodicWave(context, timbre);
    final detunes = timbre.detuneCents == 0
        ? const [0.0]
        : [0.0, timbre.detuneCents];
    final peakScale = timbre.peakGain / math.sqrt(detunes.length);

    // Ramp up from silence so starting mid-wave doesn't click.
    final envelope = context.createGain();
    envelope.gain.setValueAtTime(0, when);
    envelope.gain.linearRampToValueAtTime(
      gain * peakScale,
      when + timbre.attackSeconds,
    );
    envelope.connect(destination);

    // Lowering the cutoff after the attack keeps the initial strike brighter
    // than the ringing tail without changing the note's fundamental.
    final filter = context.createBiquadFilter()..type = 'lowpass';
    filter.Q.value = 0.5;
    filter.frequency.setValueAtTime(timbre.filterStartHz, when);
    if (timbre.filterEndHz != timbre.filterStartHz) {
      filter.frequency.setTargetAtTime(
        timbre.filterEndHz,
        when + timbre.attackSeconds,
        timbre.filterSweepSeconds / 3,
      );
    }
    filter.connect(envelope);

    final oscillators = [
      for (final detune in detunes)
        context.createOscillator()
          ..setPeriodicWave(wave)
          ..frequency.value = frequencyHz
          ..detune.value = detune,
    ];
    for (final oscillator in oscillators) {
      oscillator.connect(filter);
      oscillator.start(when);
    }
    return _Voice(oscillators, filter, envelope, peakScale);
  }

  static web.PeriodicWave _periodicWave(
    web.AudioContext context,
    InstrumentTimbre timbre,
  ) {
    // Fourier bin zero is the DC offset. The following sine coefficients
    // weight the fundamental and its integer multiples to color the tone.
    final real = <JSNumber>[0.toJS];
    final imag = <JSNumber>[0.toJS];
    for (final amplitude in timbre.harmonics) {
      real.add(0.toJS);
      imag.add(amplitude.toJS);
    }
    return context.createPeriodicWave(real.toJS, imag.toJS);
  }

  static void _prune(List<_Voice> voices, double now) {
    voices.removeWhere((voice) {
      if (voice.endTime > now) return false;
      voice.disconnect();
      return true;
    });
  }

  @override
  Future<void> dispose() async {
    stopDrone();
    stopNotes();
    final context = _context;
    _context = null;
    _droneBus = null;
    _notesBus = null;
    _waves.clear();
    if (context != null) await context.close().toDart;
  }
}

/// Web Audio nodes for one synthesized note, including any detuned oscillator.
///
/// Tracks the time at which the voice stops so expired nodes can be disconnected.
class _Voice {
  _Voice(this.oscillators, this.filter, this.envelope, this.peakScale);

  final List<web.OscillatorNode> oscillators;
  final web.BiquadFilterNode filter;
  final web.GainNode envelope;

  /// Envelope gain corresponding to a voice gain of 1.
  final double peakScale;
  double endTime = double.infinity;

  void stopAt(double time) {
    for (final oscillator in oscillators) {
      try {
        oscillator.stop(time);
      } catch (_) {
        // Already stopped.
      }
    }
    endTime = time;
  }

  void release(double now, double seconds) {
    final gain = envelope.gain;
    final current = gain.value;
    gain.cancelScheduledValues(now);
    gain.setValueAtTime(current, now);
    gain.setTargetAtTime(0, now, seconds / 3);
    stopAt(now + seconds * 2);
  }

  void disconnect() {
    for (final oscillator in oscillators) {
      oscillator.disconnect();
    }
    filter.disconnect();
    envelope.disconnect();
  }
}
