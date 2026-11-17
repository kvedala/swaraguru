// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pitch_evaluation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PitchReading _$PitchReadingFromJson(Map<String, dynamic> json) => PitchReading(
  frequencyHz: (json['frequencyHz'] as num).toDouble(),
  clarity: (json['clarity'] as num).toDouble(),
  rms: (json['rms'] as num).toDouble(),
);

Map<String, dynamic> _$PitchReadingToJson(PitchReading instance) =>
    <String, dynamic>{
      'frequencyHz': instance.frequencyHz,
      'clarity': instance.clarity,
      'rms': instance.rms,
    };

IdentifiedSwara _$IdentifiedSwaraFromJson(Map<String, dynamic> json) =>
    IdentifiedSwara(
      note: SwaraNote.fromJson(json['note'] as Map<String, dynamic>),
      frequencyHz: (json['frequencyHz'] as num).toDouble(),
      centsOff: (json['centsOff'] as num).toDouble(),
      inRaga: json['inRaga'] as bool,
    );

Map<String, dynamic> _$IdentifiedSwaraToJson(IdentifiedSwara instance) =>
    <String, dynamic>{
      'note': instance.note.toJson(),
      'frequencyHz': instance.frequencyHz,
      'centsOff': instance.centsOff,
      'inRaga': instance.inRaga,
    };

StepPitchEvaluation _$StepPitchEvaluationFromJson(Map<String, dynamic> json) =>
    StepPitchEvaluation(
      stepIndex: (json['stepIndex'] as num).toInt(),
      expected: SwaraNote.fromJson(json['expected'] as Map<String, dynamic>),
      expectedFreqHz: (json['expectedFreqHz'] as num).toDouble(),
      status: $enumDecode(_$NoteMatchStatusEnumMap, json['status']),
      message: json['message'] as String,
      sung: json['sung'] == null
          ? null
          : SwaraNote.fromJson(json['sung'] as Map<String, dynamic>),
      sungFreqHz: (json['sungFreqHz'] as num?)?.toDouble(),
      centDeviation: (json['centDeviation'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$StepPitchEvaluationToJson(
  StepPitchEvaluation instance,
) => <String, dynamic>{
  'stepIndex': instance.stepIndex,
  'expected': instance.expected.toJson(),
  'expectedFreqHz': instance.expectedFreqHz,
  'sung': instance.sung?.toJson(),
  'sungFreqHz': instance.sungFreqHz,
  'centDeviation': instance.centDeviation,
  'status': _$NoteMatchStatusEnumMap[instance.status]!,
  'message': instance.message,
};

const _$NoteMatchStatusEnumMap = {
  NoteMatchStatus.match: 'match',
  NoteMatchStatus.apasruti: 'apasruti',
  NoteMatchStatus.wrongSwara: 'wrongSwara',
  NoteMatchStatus.noVoice: 'noVoice',
};
