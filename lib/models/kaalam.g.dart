// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kaalam.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KaalamSpeed _$KaalamSpeedFromJson(Map<String, dynamic> json) => KaalamSpeed(
  kaalam: (json['kaalam'] as num).toInt(),
  name: json['name'] as String,
  sanskritName: json['sanskritName'] as String,
  swarasPerBeat: (json['swarasPerBeat'] as num).toInt(),
);

Map<String, dynamic> _$KaalamSpeedToJson(KaalamSpeed instance) =>
    <String, dynamic>{
      'kaalam': instance.kaalam,
      'name': instance.name,
      'sanskritName': instance.sanskritName,
      'swarasPerBeat': instance.swarasPerBeat,
    };
