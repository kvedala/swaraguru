import 'package:json_annotation/json_annotation.dart';

import 'raga.dart';
import 'swara.dart';

part 'carnatic_lesson.g.dart';

/// A practice exercise such as a Sarali Varisai or Geetham, stored as raw
/// notation tokens so that unnumbered letters follow the session raga.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CarnaticLesson {
  const CarnaticLesson({
    required this.id,
    required this.group,
    required this.title,
    required this.raga,
    this.flatNotation = const [],
    this.tala = 'Adi Tala (8 Beats)',
    this.description = '',
    this.combo,
    this.sequence,
    this.notationRows,
    this.score,
    this.sourceArohanam,
    this.sourceAvarohanam,
  });

  /// Arohanam followed by avarohanam for [raga].
  factory CarnaticLesson.ragaScale(Raga raga) => CarnaticLesson(
    id: 'scale-${raga.name.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}',
    group: 'Raga Scale',
    title: '${raga.name} — Arohanam & Avarohanam',
    raga: raga.name,
    description: 'Ascend and descend through the ${raga.name} scale.',
    flatNotation: [
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

  final int? combo;
  final int? sequence;
  final String? sourceArohanam;
  final String? sourceAvarohanam;

  /// Rows of beat cells for exercises with one written pattern.
  final List<List<String>>? notationRows;

  final List<GeetamSection>? score;

  @JsonKey(
    name: 'notation',
    fromJson: _readFlatNotation,
    toJson: _writeFlatNotation,
  )
  final List<String> flatNotation;

  Iterable<({String token, String? lyric, bool startsRow, bool startsCell})>
  _notation() sync* {
    if (score case final sections?) {
      for (final section in sections) {
        for (final row in section.rows) {
          var startsRow = true;
          for (final cell in row) {
            var startsCell = true;
            String? lyric = cell.lyric;
            for (final token in tokenizeNotation(cell.notation)) {
              yield (token: token, lyric: lyric, startsRow: startsRow, startsCell: startsCell);
              startsRow = false;
              startsCell = false;
              lyric = null;
            }
          }
        }
      }
    } else if (notationRows case final rows?) {
      for (final row in rows) {
        var startsRow = true;
        for (final cell in row) {
          var startsCell = true;
          for (final token in tokenizeNotation(cell)) {
            yield (token: token, lyric: null, startsRow: startsRow, startsCell: startsCell);
            startsRow = false;
            startsCell = false;
          }
        }
      }
    } else {
      for (final token in flatNotation) {
        yield (token: token, lyric: null, startsRow: false, startsCell: false);
      }
    }
  }

  List<String> get swaras =>
      [for (final entry in _notation()) entry.token];

  Map<String, dynamic> toJson() => _$CarnaticLessonToJson(this);

  /// Resolves every token against [scale]. A karvai (`,`) sustains the
  /// previous swara, so it carries that note with [LessonStep.isKarvai] set.
  List<LessonStep> stepsFor(RagaScale scale) {
    final steps = <LessonStep>[];
    SwaraNote? previous;
    for (final (:token, :lyric, :startsRow, :startsCell) in _notation()) {
      final isKarvai = token.isKarvai;
      if (!isKarvai) previous = scale.resolve(token);
      steps.add(
        LessonStep(
          token: token,
          note: previous,
          isKarvai: isKarvai,
          lyric: lyric,
          startsRow: startsRow,
          startsCell: startsCell,
        ),
      );
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

List<String> _readFlatNotation(String? value) =>
    value == null ? const [] : tokenizeNotation(value);

String? _writeFlatNotation(List<String> tokens) =>
    tokens.isEmpty ? null : tokens.join(' ');

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class GeetamSection {
  const GeetamSection({
    required this.name,
    required this.rows,
    this.sangathi,
    this.lyrics,
  });

  factory GeetamSection.fromJson(Map<String, dynamic> json) =>
      _$GeetamSectionFromJson(json);

  final String name;
  final int? sangathi;
  final List<String>? lyrics;
  final List<List<GeetamCell>> rows;

  Map<String, dynamic> toJson() => _$GeetamSectionToJson(this);
}

@JsonSerializable()
class GeetamCell {
  const GeetamCell({required this.notation, required this.lyric});

  factory GeetamCell.fromJson(Map<String, dynamic> json) =>
      _$GeetamCellFromJson(json);

  final String notation;
  final String lyric;

  Map<String, dynamic> toJson() => _$GeetamCellToJson(this);
}

/// One beat-subdivision of a lesson after resolving it in a raga.
class LessonStep {
  const LessonStep({
    required this.token,
    this.note,
    this.isKarvai = false,
    this.lyric,
    this.startsRow = false,
    this.startsCell = false,
  });

  final String token;

  /// The sounding swara; `null` only for a leading karvai.
  final SwaraNote? note;
  final bool isKarvai;
  final String? lyric;

  /// Whether this is the first swara of a written score row.
  final bool startsRow;

  /// Whether this starts a written notation cell within a score row.
  final bool startsCell;

  String get label => isKarvai ? ',' : note?.label ?? token;
}
