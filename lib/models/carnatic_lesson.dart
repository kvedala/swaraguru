import 'package:json_annotation/json_annotation.dart';

import 'raga.dart';
import 'swara.dart';

part 'carnatic_lesson.g.dart';

/// A practice exercise such as a Sarali Varisai or Geetham, stored as raw
/// notation tokens so that unnumbered letters follow the session raga.
@JsonSerializable()
class CarnaticLesson {
  const CarnaticLesson({
    required this.id,
    required this.group,
    required this.title,
    required this.raga,
    required this.swaras,
    this.tala = 'Adi Tala (8 Beats)',
    this.description = '',
  });

  /// Arohanam followed by avarohanam for [raga].
  factory CarnaticLesson.ragaScale(Raga raga) => CarnaticLesson(
    id: 'scale-${raga.name.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}',
    group: 'Raga Scale',
    title: '${raga.name} — Arohanam & Avarohanam',
    raga: raga.name,
    description: 'Ascend and descend through the ${raga.name} scale.',
    swaras: [
      for (final note in [...raga.arohanam, ...raga.avarohanam]) note.label,
    ],
  );

  factory CarnaticLesson.fromJson(Map<String, dynamic> json) =>
      _$CarnaticLessonFromJson(json);

  final String id;
  final String group;
  final String title;

  /// Name of the raga this lesson is taught in.
  final String raga;
  final String tala;
  final String description;

  @JsonKey(name: 'notation', fromJson: tokenizeNotation, toJson: _joinNotation)
  final List<String> swaras;

  Map<String, dynamic> toJson() => _$CarnaticLessonToJson(this);

  /// Resolves every token against [scale]. A karvai (`,`) sustains the
  /// previous swara, so it carries that note with [LessonStep.isKarvai] set.
  List<LessonStep> stepsFor(RagaScale scale) {
    final steps = <LessonStep>[];
    SwaraNote? previous;
    for (final token in swaras) {
      if (token.isKarvai) {
        steps.add(LessonStep(token: token, note: previous, isKarvai: true));
        continue;
      }
      previous = scale.resolve(token);
      steps.add(LessonStep(token: token, note: previous));
    }
    return steps;
  }

  /// Tokens that are neither swaras nor karvai.
  List<String> get invalidTokens => [
    for (final token in swaras)
      if (!token.isKarvai && token.toSwaraNote() == null) token,
  ];
}

List<String> tokenizeNotation(String notation) => [
  for (final token in notation.trim().split(RegExp(r'\s+')))
    if (token.isNotEmpty) token,
];

String _joinNotation(List<String> tokens) => tokens.join(' ');

/// One beat-subdivision of a lesson after resolving it in a raga.
class LessonStep {
  const LessonStep({required this.token, this.note, this.isKarvai = false});

  final String token;

  /// The sounding swara; `null` only for a leading karvai.
  final SwaraNote? note;
  final bool isKarvai;

  String get label => isKarvai ? ',' : note?.label ?? token;
}
