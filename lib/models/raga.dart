import 'package:json_annotation/json_annotation.dart';

import 'swara.dart';

part 'raga.g.dart';

/// A Carnatic raga: one of the 72 melakartas or a janya (derived) raga.
@JsonSerializable()
class Raga {
  const Raga({
    required this.name,
    required this.arohanam,
    required this.avarohanam,
    this.melakarta,
    this.parentMelakarta,
    this.aliases = const [],
  });

  factory Raga.fromJson(Map<String, dynamic> json) => _$RagaFromJson(json);

  final String name;

  /// Melakarta number (1–72) when this raga is itself a melakarta.
  final int? melakarta;

  /// Melakarta number this janya raga derives from.
  final int? parentMelakarta;

  final List<String> aliases;

  @JsonKey(fromJson: parseSwaraNotes, toJson: formatSwaraNotes)
  final List<SwaraNote> arohanam;

  @JsonKey(fromJson: parseSwaraNotes, toJson: formatSwaraNotes)
  final List<SwaraNote> avarohanam;

  Map<String, dynamic> toJson() => _$RagaToJson(this);

  bool get isMelakarta => melakarta != null;

  String get classification => switch ((melakarta, parentMelakarta)) {
    (final int number, _) => 'Melakarta $number',
    (_, final int parent) => 'Janya of Mela $parent',
    _ => 'Janya',
  };

  /// Swaras used anywhere in the arohanam or avarohanam.
  Set<Swara> get swaras => {
    for (final note in [...arohanam, ...avarohanam]) note.swara,
  };

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        aliases.any((alias) => alias.toLowerCase().contains(q)) ||
        '$melakarta' == q;
  }

  @override
  bool operator ==(Object other) => other is Raga && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// Resolves notation and pitch positions within a raga, falling back to the
/// parent melakarta and then to the canonical swara names.
class RagaScale {
  factory RagaScale(Raga raga, {Raga? parent}) {
    final letters = Map<SwaraLetter, Swara>.of(kDefaultLetterSwaras);
    final byPosition = <int, Swara>{};
    final parentByPosition = <int, Swara>{};

    void collect(Raga source, Map<int, Swara> positions) {
      final seenLetters = <SwaraLetter>{};
      for (final swara in source.swaras) {
        if (seenLetters.add(swara.letter)) letters[swara.letter] = swara;
        positions.putIfAbsent(swara.position, () => swara);
      }
    }

    if (parent != null) collect(parent, parentByPosition);
    collect(raga, byPosition);
    return RagaScale._(raga, letters, byPosition, parentByPosition);
  }

  RagaScale._(
    this.raga,
    this.letters,
    this._byPosition,
    this._parentByPosition,
  );

  final Raga raga;

  /// Swara used for each letter written without a variant number.
  final Map<SwaraLetter, Swara> letters;
  final Map<int, Swara> _byPosition;
  final Map<int, Swara> _parentByPosition;

  SwaraNote? resolve(String token) => token.toSwaraNote(letters);

  bool containsPosition(int position) => _byPosition.containsKey(position % 12);

  /// Name for a pitch position, preferring this raga's own swara names.
  Swara swaraAt(int position) {
    final p = position % 12;
    return _byPosition[p] ??
        _parentByPosition[p] ??
        kCanonicalSwaraByPosition[p];
  }
}
