import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

import 'carnatic_lesson.dart';
import 'raga.dart';

part 'carnatic_catalog.g.dart';

/// Ragas and lessons bundled with the app under `assets/data/`.
@JsonSerializable()
class CarnaticCatalog {
  CarnaticCatalog({required this.ragas, required this.lessons});

  factory CarnaticCatalog.fromJson(Map<String, dynamic> json) =>
      _$CarnaticCatalogFromJson(json);

  static const ragasAsset = 'assets/data/ragas.json';
  static const lessonsAsset = 'assets/data/lessons.json';
  static const defaultRagaName = 'Mayamalavagowla';

  static Future<CarnaticCatalog> load(AssetBundle bundle) async {
    final [ragas, lessons] = await Future.wait([
      bundle.loadString(ragasAsset),
      bundle.loadString(lessonsAsset),
    ]);
    return CarnaticCatalog.fromJson({
      ...jsonDecode(ragas) as Map<String, dynamic>,
      ...jsonDecode(lessons) as Map<String, dynamic>,
    });
  }

  final List<Raga> ragas;
  final List<CarnaticLesson> lessons;

  Map<String, dynamic> toJson() => _$CarnaticCatalogToJson(this);

  late final Map<String, Raga> _byName = {
    for (final raga in ragas) ...{
      _key(raga.name): raga,
      for (final alias in raga.aliases) _key(alias): raga,
    },
  };

  late final Map<int, Raga> _melakartas = {
    for (final raga in ragas)
      if (raga.melakarta != null) raga.melakarta!: raga,
  };

  static String _key(String name) => name
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(RegExp(r'[^A-Za-z]'), '')
      .toLowerCase();

  /// Looks up a raga by name or alias, ignoring case, spacing and any
  /// parenthetical note such as "(15th Melakarta)".
  Raga? ragaNamed(String name) => _byName[_key(name)];

  Raga? melakarta(int number) => _melakartas[number];

  Raga get defaultRaga => ragaNamed(defaultRagaName) ?? ragas.first;

  RagaScale scaleFor(Raga raga) {
    final parentNumber = raga.parentMelakarta;
    return RagaScale(
      raga,
      parent: parentNumber == null ? null : melakarta(parentNumber),
    );
  }

  /// Ragas ordered alphabetically for pickers.
  List<Raga> get sortedRagas =>
      [...ragas]..sort((a, b) => a.name.compareTo(b.name));
}
