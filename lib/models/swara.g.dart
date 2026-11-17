// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swara.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwaraNote _$SwaraNoteFromJson(Map<String, dynamic> json) => SwaraNote(
  $enumDecode(_$SwaraEnumMap, json['swara']),
  (json['octave'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SwaraNoteToJson(SwaraNote instance) => <String, dynamic>{
  'swara': _$SwaraEnumMap[instance.swara]!,
  'octave': instance.octave,
};

const _$SwaraEnumMap = {
  Swara.s: 'S',
  Swara.r1: 'R1',
  Swara.r2: 'R2',
  Swara.r3: 'R3',
  Swara.g1: 'G1',
  Swara.g2: 'G2',
  Swara.g3: 'G3',
  Swara.m1: 'M1',
  Swara.m2: 'M2',
  Swara.p: 'P',
  Swara.d1: 'D1',
  Swara.d2: 'D2',
  Swara.d3: 'D3',
  Swara.n1: 'N1',
  Swara.n2: 'N2',
  Swara.n3: 'N3',
};
