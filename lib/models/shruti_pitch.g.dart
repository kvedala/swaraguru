// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shruti_pitch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShrutiPitch _$ShrutiPitchFromJson(Map<String, dynamic> json) => ShrutiPitch(
  id: json['id'] as String,
  kattai: (json['kattai'] as num).toDouble(),
  frequencyHz: (json['frequencyHz'] as num).toDouble(),
);

Map<String, dynamic> _$ShrutiPitchToJson(ShrutiPitch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kattai': instance.kattai,
      'frequencyHz': instance.frequencyHz,
    };
