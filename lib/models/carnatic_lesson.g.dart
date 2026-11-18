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
      flatNotation: json['notation'] == null
          ? const []
          : _readFlatNotation(json['notation'] as String?),
      tala: json['tala'] as String? ?? 'Adi Tala (8 Beats)',
      description: json['description'] as String? ?? '',
      combo: (json['combo'] as num?)?.toInt(),
      sequence: (json['sequence'] as num?)?.toInt(),
      notationRows: (json['notationRows'] as List<dynamic>?)
          ?.map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList(),
      score: (json['score'] as List<dynamic>?)
          ?.map((e) => GeetamSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      sourceArohanam: json['sourceArohanam'] as String?,
      sourceAvarohanam: json['sourceAvarohanam'] as String?,
    );

Map<String, dynamic> _$CarnaticLessonToJson(CarnaticLesson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group': instance.group,
      'title': instance.title,
      'raga': instance.raga,
      'tala': instance.tala,
      'description': instance.description,
      'combo': ?instance.combo,
      'sequence': ?instance.sequence,
      'sourceArohanam': ?instance.sourceArohanam,
      'sourceAvarohanam': ?instance.sourceAvarohanam,
      'notationRows': ?instance.notationRows,
      'score': ?instance.score?.map((e) => e.toJson()).toList(),
      'notation': ?_writeFlatNotation(instance.flatNotation),
    };

GeetamSection _$GeetamSectionFromJson(Map<String, dynamic> json) =>
    GeetamSection(
      name: json['name'] as String,
      rows: (json['rows'] as List<dynamic>)
          .map(
            (e) => (e as List<dynamic>)
                .map((e) => GeetamCell.fromJson(e as Map<String, dynamic>))
                .toList(),
          )
          .toList(),
      sangathi: (json['sangathi'] as num?)?.toInt(),
      lyrics: (json['lyrics'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$GeetamSectionToJson(
  GeetamSection instance,
) => <String, dynamic>{
  'name': instance.name,
  'sangathi': ?instance.sangathi,
  'lyrics': ?instance.lyrics,
  'rows': instance.rows.map((e) => e.map((e) => e.toJson()).toList()).toList(),
};

GeetamCell _$GeetamCellFromJson(Map<String, dynamic> json) => GeetamCell(
  notation: json['notation'] as String,
  lyric: json['lyric'] as String,
);

Map<String, dynamic> _$GeetamCellToJson(GeetamCell instance) =>
    <String, dynamic>{'notation': instance.notation, 'lyric': instance.lyric};
