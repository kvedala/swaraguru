// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DroneVoice _$DroneVoiceFromJson(Map<String, dynamic> json) => DroneVoice(
  frequencyHz: (json['frequencyHz'] as num).toDouble(),
  gain: (json['gain'] as num).toDouble(),
);

Map<String, dynamic> _$DroneVoiceToJson(DroneVoice instance) =>
    <String, dynamic>{
      'frequencyHz': instance.frequencyHz,
      'gain': instance.gain,
    };

DroneSound _$DroneSoundFromJson(Map<String, dynamic> json) => DroneSound(
  voices: (json['voices'] as List<dynamic>)
      .map((e) => DroneVoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  volume: (json['volume'] as num).toDouble(),
  instrument: $enumDecode(_$SwaraInstrumentEnumMap, json['instrument']),
);

Map<String, dynamic> _$DroneSoundToJson(DroneSound instance) =>
    <String, dynamic>{
      'voices': instance.voices.map((e) => e.toJson()).toList(),
      'volume': instance.volume,
      'instrument': _$SwaraInstrumentEnumMap[instance.instrument]!,
    };

const _$SwaraInstrumentEnumMap = {
  SwaraInstrument.tampura: 'tampura',
  SwaraInstrument.harmonium: 'harmonium',
  SwaraInstrument.piano: 'piano',
};

DroneSettings _$DroneSettingsFromJson(Map<String, dynamic> json) =>
    DroneSettings(
      mode:
          $enumDecodeNullable(_$DroneModeEnumMap, json['mode']) ??
          DroneMode.pureSingleNote,
      pureChannel:
          $enumDecodeNullable(_$DroneChannelEnumMap, json['pureChannel']) ??
          DroneChannel.sa,
      singleNoteInstrument:
          $enumDecodeNullable(
            _$SwaraInstrumentEnumMap,
            json['singleNoteInstrument'],
          ) ??
          SwaraInstrument.harmonium,
      mix: (json['mix'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          $enumDecode(_$DroneChannelEnumMap, k),
          (e as num).toDouble(),
        ),
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 0.55,
      instrument:
          $enumDecodeNullable(_$SwaraInstrumentEnumMap, json['instrument']) ??
          SwaraInstrument.tampura,
    );

Map<String, dynamic> _$DroneSettingsToJson(DroneSettings instance) =>
    <String, dynamic>{
      'mode': _$DroneModeEnumMap[instance.mode]!,
      'pureChannel': _$DroneChannelEnumMap[instance.pureChannel]!,
      'singleNoteInstrument':
          _$SwaraInstrumentEnumMap[instance.singleNoteInstrument]!,
      'mix': instance.mix.map((k, e) => MapEntry(_$DroneChannelEnumMap[k]!, e)),
      'volume': instance.volume,
      'instrument': _$SwaraInstrumentEnumMap[instance.instrument]!,
    };

const _$DroneModeEnumMap = {
  DroneMode.pureSingleNote: 'pureSingleNote',
  DroneMode.multiNoteChord: 'multiNoteChord',
};

const _$DroneChannelEnumMap = {
  DroneChannel.mandraPa: 'mandraPa',
  DroneChannel.mandraNi: 'mandraNi',
  DroneChannel.sa: 'sa',
  DroneChannel.ma1: 'ma1',
  DroneChannel.ma2: 'ma2',
  DroneChannel.pa: 'pa',
  DroneChannel.ni3: 'ni3',
  DroneChannel.taraSa: 'taraSa',
};
