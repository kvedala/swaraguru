import 'package:json_annotation/json_annotation.dart';

import 'instrument.dart';
import 'swara.dart';

part 'drone_settings.g.dart';

@JsonEnum()
enum DroneMode { pureSingleNote, multiNoteChord }

extension DroneModeInfo on DroneMode {
  String get label => switch (this) {
    DroneMode.pureSingleNote => 'Pure Single Note',
    DroneMode.multiNoteChord => 'Multi-Note Tampura',
  };
}

/// The strings available in the Shruti mixer.
@JsonEnum()
enum DroneChannel { mandraPa, mandraNi, sa, ma1, ma2, pa, ni3, taraSa }

extension DroneChannelInfo on DroneChannel {
  SwaraNote get note => switch (this) {
    DroneChannel.mandraPa => const SwaraNote(Swara.p, -1),
    DroneChannel.mandraNi => const SwaraNote(Swara.n3, -1),
    DroneChannel.sa => const SwaraNote(Swara.s),
    DroneChannel.ma1 => const SwaraNote(Swara.m1),
    DroneChannel.ma2 => const SwaraNote(Swara.m2),
    DroneChannel.pa => const SwaraNote(Swara.p),
    DroneChannel.ni3 => const SwaraNote(Swara.n3),
    DroneChannel.taraSa => const SwaraNote(Swara.s, 1),
  };

  String get label => note.label;
}

/// Traditional tampura tunings.
enum DronePreset { pa, ma, ni, saOnly }

extension DronePresetInfo on DronePreset {
  String get label => switch (this) {
    DronePreset.pa => 'Pa Tuning',
    DronePreset.ma => 'Ma Tuning',
    DronePreset.ni => 'Ni Tuning',
    DronePreset.saOnly => 'Sa Only',
  };

  String get description => switch (this) {
    DronePreset.pa => 'P̣ S S Ṡ — the default for most ragas.',
    DronePreset.ma => 'S M S Ṡ — for ragas without Panchamam.',
    DronePreset.ni => 'Ṇ S N Ṡ — for ragas without Pa or Ma.',
    DronePreset.saOnly => 'S Ṡ — a bare Shadja reference.',
  };

  Map<DroneChannel, double> get mix => {
    for (final channel in DroneChannel.values) channel: 0.0,
    ...switch (this) {
      DronePreset.pa => {
        DroneChannel.mandraPa: 0.45,
        DroneChannel.sa: 0.95,
        DroneChannel.pa: 0.80,
        DroneChannel.taraSa: 0.70,
      },
      DronePreset.ma => {
        DroneChannel.sa: 0.95,
        DroneChannel.ma1: 0.80,
        DroneChannel.taraSa: 0.70,
      },
      DronePreset.ni => {
        DroneChannel.mandraNi: 0.45,
        DroneChannel.sa: 0.95,
        DroneChannel.ni3: 0.60,
        DroneChannel.taraSa: 0.70,
      },
      DronePreset.saOnly => {DroneChannel.sa: 0.95, DroneChannel.taraSa: 0.80},
    },
  };
}

/// A single sounding pitch in the drone.
@JsonSerializable()
class DroneVoice {
  const DroneVoice({required this.frequencyHz, required this.gain});

  factory DroneVoice.fromJson(Map<String, dynamic> json) =>
      _$DroneVoiceFromJson(json);

  final double frequencyHz;
  final double gain;

  Map<String, dynamic> toJson() => _$DroneVoiceToJson(this);

  @override
  bool operator ==(Object other) =>
      other is DroneVoice &&
      other.frequencyHz == frequencyHz &&
      other.gain == gain;

  @override
  int get hashCode => Object.hash(frequencyHz, gain);
}

/// Everything the audio engine needs to render the drone.
@JsonSerializable()
class DroneSound {
  const DroneSound({
    required this.voices,
    required this.volume,
    required this.instrument,
  });

  factory DroneSound.fromJson(Map<String, dynamic> json) =>
      _$DroneSoundFromJson(json);

  final List<DroneVoice> voices;
  final double volume;
  final SwaraInstrument instrument;

  Map<String, dynamic> toJson() => _$DroneSoundToJson(this);
}

/// User-adjustable Shruti box configuration.
@JsonSerializable()
class DroneSettings {
  DroneSettings({
    this.mode = DroneMode.multiNoteChord,
    this.pureChannel = DroneChannel.sa,
    Map<DroneChannel, double>? mix,
    this.volume = 0.55,
    this.instrument = SwaraInstrument.tampura,
  }) : mix = Map.unmodifiable(mix ?? DronePreset.pa.mix);

  factory DroneSettings.fromJson(Map<String, dynamic> json) =>
      _$DroneSettingsFromJson(json);

  final DroneMode mode;
  final DroneChannel pureChannel;
  final Map<DroneChannel, double> mix;
  final double volume;
  final SwaraInstrument instrument;

  Map<String, dynamic> toJson() => _$DroneSettingsToJson(this);

  DroneSettings copyWith({
    DroneMode? mode,
    DroneChannel? pureChannel,
    Map<DroneChannel, double>? mix,
    double? volume,
    SwaraInstrument? instrument,
  }) => DroneSettings(
    mode: mode ?? this.mode,
    pureChannel: pureChannel ?? this.pureChannel,
    mix: mix ?? this.mix,
    volume: volume ?? this.volume,
    instrument: instrument ?? this.instrument,
  );

  DroneSettings withLevel(DroneChannel channel, double level) =>
      copyWith(mix: {...mix, channel: level});

  double levelOf(DroneChannel channel) => mix[channel] ?? 0;

  List<DroneVoice> voicesFor(double saHz) => switch (mode) {
    DroneMode.pureSingleNote => [
      DroneVoice(frequencyHz: pureChannel.note.frequencyFor(saHz), gain: 1),
    ],
    DroneMode.multiNoteChord => [
      for (final channel in DroneChannel.values)
        if (levelOf(channel) > 0)
          DroneVoice(
            frequencyHz: channel.note.frequencyFor(saHz),
            gain: levelOf(channel),
          ),
    ],
  };

  DroneSound soundFor(double saHz) => DroneSound(
    voices: voicesFor(saHz),
    volume: volume,
    instrument: instrument,
  );

  String get summary {
    if (mode == DroneMode.pureSingleNote) return 'Pure ${pureChannel.label}';
    final active = [
      for (final channel in DroneChannel.values)
        if (levelOf(channel) > 0.05) channel.label,
    ];
    return active.isEmpty ? 'Muted' : 'Multi (${active.join(' + ')})';
  }
}
