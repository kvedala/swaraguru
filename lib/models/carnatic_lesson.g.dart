// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carnatic_lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarnaticLesson _$CarnaticLessonFromJson(Map<String, dynamic> json) =>
    CarnaticLesson(
      id: json['id'] as String,
      group: json['group'] as String,
      title: json['title'] as String,
      raga: json['raga'] as String,
      swaras: tokenizeNotation(json['notation'] as String),
      tala: json['tala'] as String? ?? 'Adi Tala (8 Beats)',
      description: json['description'] as String? ?? '',
    );

Map<String, dynamic> _$CarnaticLessonToJson(CarnaticLesson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group': instance.group,
      'title': instance.title,
      'raga': instance.raga,
      'tala': instance.tala,
      'description': instance.description,
      'notation': _joinNotation(instance.swaras),
    };
