// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raga.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Raga _$RagaFromJson(Map<String, dynamic> json) => Raga(
  name: json['name'] as String,
  arohanam: parseSwaraNotes(json['arohanam'] as String),
  avarohanam: parseSwaraNotes(json['avarohanam'] as String),
  melakarta: (json['melakarta'] as num?)?.toInt(),
  parentMelakarta: (json['parentMelakarta'] as num?)?.toInt(),
  aliases:
      (json['aliases'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$RagaToJson(Raga instance) => <String, dynamic>{
  'name': instance.name,
  'melakarta': instance.melakarta,
  'parentMelakarta': instance.parentMelakarta,
  'aliases': instance.aliases,
  'arohanam': formatSwaraNotes(instance.arohanam),
  'avarohanam': formatSwaraNotes(instance.avarohanam),
};
