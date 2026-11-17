// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carnatic_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarnaticCatalog _$CarnaticCatalogFromJson(Map<String, dynamic> json) =>
    CarnaticCatalog(
      ragas: (json['ragas'] as List<dynamic>)
          .map((e) => Raga.fromJson(e as Map<String, dynamic>))
          .toList(),
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => CarnaticLesson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CarnaticCatalogToJson(CarnaticCatalog instance) =>
    <String, dynamic>{
      'ragas': instance.ragas.map((e) => e.toJson()).toList(),
      'lessons': instance.lessons.map((e) => e.toJson()).toList(),
    };
