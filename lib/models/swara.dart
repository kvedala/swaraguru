import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';

part 'swara.g.dart';

/// The seven letters of Carnatic sargam notation.
enum SwaraLetter { s, r, g, m, p, d, n }

extension SwaraLetterInfo on SwaraLetter {
  String get symbol => switch (this) {
    SwaraLetter.s => 'S',
    SwaraLetter.r => 'R',
    SwaraLetter.g => 'G',
    SwaraLetter.m => 'M',
    SwaraLetter.p => 'P',
    SwaraLetter.d => 'D',
    SwaraLetter.n => 'N',
  };

  String get telugu => switch (this) {
    SwaraLetter.s => 'స',
    SwaraLetter.r => 'రి',
    SwaraLetter.g => 'గ',
    SwaraLetter.m => 'మ',
    SwaraLetter.p => 'ప',
    SwaraLetter.d => 'ద',
    SwaraLetter.n => 'ని',
  };
}

/// The sixteen Carnatic swarasthana names. Several names share one of the
/// twelve positions in the octave (for example R2 and G1).
@JsonEnum()
enum Swara {
  @JsonValue('S')
  s,
  @JsonValue('R1')
  r1,
  @JsonValue('R2')
  r2,
  @JsonValue('R3')
  r3,
  @JsonValue('G1')
  g1,
  @JsonValue('G2')
  g2,
  @JsonValue('G3')
  g3,
  @JsonValue('M1')
  m1,
  @JsonValue('M2')
  m2,
  @JsonValue('P')
  p,
  @JsonValue('D1')
  d1,
  @JsonValue('D2')
  d2,
  @JsonValue('D3')
  d3,
  @JsonValue('N1')
  n1,
  @JsonValue('N2')
  n2,
  @JsonValue('N3')
  n3,
}

/// Swara used for each of the twelve positions when no raga names it.
const List<Swara> kCanonicalSwaraByPosition = [
  Swara.s,
  Swara.r1,
  Swara.r2,
  Swara.g2,
  Swara.g3,
  Swara.m1,
  Swara.m2,
  Swara.p,
  Swara.d1,
  Swara.d2,
  Swara.n2,
  Swara.n3,
];

/// Traditional teaching defaults (Mayamalavagowla) for letters written
/// without a variant number, such as `R` or `G`.
const Map<SwaraLetter, Swara> kDefaultLetterSwaras = {
  SwaraLetter.s: Swara.s,
  SwaraLetter.r: Swara.r1,
  SwaraLetter.g: Swara.g3,
  SwaraLetter.m: Swara.m1,
  SwaraLetter.p: Swara.p,
  SwaraLetter.d: Swara.d1,
  SwaraLetter.n: Swara.n3,
};

// Sa, Ma (4/3), Pa (3/2) and upper Sa (2) are tuned as pure intervals; the
// remaining positions are interpolated geometrically between these anchors.
const List<(int position, double ratio)> _kTuningAnchors = [
  (0, 1.0),
  (5, 4 / 3),
  (7, 3 / 2),
  (12, 2.0),
];

/// Frequency ratio from Sa for a position counted in swarasthana steps
/// (0 = Sa, 7 = Pa, 12 = upper Sa, -5 = lower Pa).
double swaraPositionRatio(int position) {
  final octave = (position / 12).floor();
  final withinOctave = position - octave * 12;
  return _ratioWithinOctave(withinOctave) * math.pow(2.0, octave);
}

double _ratioWithinOctave(int position) {
  for (var i = 0; i < _kTuningAnchors.length - 1; i++) {
    final (lowPos, lowRatio) = _kTuningAnchors[i];
    final (highPos, highRatio) = _kTuningAnchors[i + 1];
    if (position == lowPos) return lowRatio;
    if (position < highPos) {
      final fraction = (position - lowPos) / (highPos - lowPos);
      return lowRatio * math.pow(highRatio / lowRatio, fraction);
    }
  }
  return 2.0;
}

double centsForRatio(double ratio) => 1200.0 * math.log(ratio) / math.ln2;

extension SwaraInfo on Swara {
  String get code => switch (this) {
    Swara.s => 'S',
    Swara.r1 => 'R1',
    Swara.r2 => 'R2',
    Swara.r3 => 'R3',
    Swara.g1 => 'G1',
    Swara.g2 => 'G2',
    Swara.g3 => 'G3',
    Swara.m1 => 'M1',
    Swara.m2 => 'M2',
    Swara.p => 'P',
    Swara.d1 => 'D1',
    Swara.d2 => 'D2',
    Swara.d3 => 'D3',
    Swara.n1 => 'N1',
    Swara.n2 => 'N2',
    Swara.n3 => 'N3',
  };

  SwaraLetter get letter => switch (this) {
    Swara.s => SwaraLetter.s,
    Swara.r1 || Swara.r2 || Swara.r3 => SwaraLetter.r,
    Swara.g1 || Swara.g2 || Swara.g3 => SwaraLetter.g,
    Swara.m1 || Swara.m2 => SwaraLetter.m,
    Swara.p => SwaraLetter.p,
    Swara.d1 || Swara.d2 || Swara.d3 => SwaraLetter.d,
    Swara.n1 || Swara.n2 || Swara.n3 => SwaraLetter.n,
  };

  /// Variant number (1–3); `null` for the fixed swaras S and P.
  int? get variant => switch (this) {
    Swara.s || Swara.p => null,
    Swara.r1 || Swara.g1 || Swara.m1 || Swara.d1 || Swara.n1 => 1,
    Swara.r2 || Swara.g2 || Swara.m2 || Swara.d2 || Swara.n2 => 2,
    Swara.r3 || Swara.g3 || Swara.d3 || Swara.n3 => 3,
  };

  /// Position within the octave, from 0 (Sa) to 11 (N3).
  int get position => switch (this) {
    Swara.s => 0,
    Swara.r1 => 1,
    Swara.r2 || Swara.g1 => 2,
    Swara.r3 || Swara.g2 => 3,
    Swara.g3 => 4,
    Swara.m1 => 5,
    Swara.m2 => 6,
    Swara.p => 7,
    Swara.d1 => 8,
    Swara.d2 || Swara.n1 => 9,
    Swara.d3 || Swara.n2 => 10,
    Swara.n3 => 11,
  };

  String get sthanaName => switch (this) {
    Swara.s => 'Shadjam',
    Swara.r1 => 'Shuddha Rishabham',
    Swara.r2 => 'Chatushruti Rishabham',
    Swara.r3 => 'Shatshruti Rishabham',
    Swara.g1 => 'Shuddha Gandharam',
    Swara.g2 => 'Sadharana Gandharam',
    Swara.g3 => 'Antara Gandharam',
    Swara.m1 => 'Shuddha Madhyamam',
    Swara.m2 => 'Prati Madhyamam',
    Swara.p => 'Panchamam',
    Swara.d1 => 'Shuddha Dhaivatam',
    Swara.d2 => 'Chatushruti Dhaivatam',
    Swara.d3 => 'Shatshruti Dhaivatam',
    Swara.n1 => 'Shuddha Nishadam',
    Swara.n2 => 'Kaisiki Nishadam',
    Swara.n3 => 'Kakali Nishadam',
  };

  String get telugu {
    final number = variant;
    return number == null
        ? letter.telugu
        : '${letter.telugu}${_kSubscriptDigits[number]}';
  }

  /// Ratio above Sa in the middle octave.
  double get ratio => swaraPositionRatio(position);

  double get cents => centsForRatio(ratio);

  double frequencyFor(double saHz) => saHz * ratio;
}

const List<String> _kSubscriptDigits = ['₀', '₁', '₂', '₃'];

Swara? swaraFor(SwaraLetter letter, int variant) {
  for (final swara in Swara.values) {
    if (swara.letter == letter && swara.variant == variant) return swara;
  }
  return null;
}

/// A swara in a specific octave: -1 = mandra, 0 = madhya, 1 = tara.
@JsonSerializable()
class SwaraNote {
  const SwaraNote(this.swara, [this.octave = 0]);

  factory SwaraNote.fromJson(Map<String, dynamic> json) =>
      _$SwaraNoteFromJson(json);

  final Swara swara;
  final int octave;

  Map<String, dynamic> toJson() => _$SwaraNoteToJson(this);

  @override
  bool operator ==(Object other) =>
      other is SwaraNote && other.swara == swara && other.octave == octave;

  @override
  int get hashCode => Object.hash(swara, octave);

  @override
  String toString() => label;
}

const String _kDotAbove = '\u0307';
const String _kDotBelow = '\u0323';

const Map<String, String> _kPrecomposedOctaveLetters = {
  'Ṡ': 'S$_kDotAbove',
  'Ṙ': 'R$_kDotAbove',
  'Ġ': 'G$_kDotAbove',
  'Ṁ': 'M$_kDotAbove',
  'Ṗ': 'P$_kDotAbove',
  'Ḋ': 'D$_kDotAbove',
  'Ṅ': 'N$_kDotAbove',
  'Ṣ': 'S$_kDotBelow',
  'Ṛ': 'R$_kDotBelow',
  'Ṃ': 'M$_kDotBelow',
  'Ḍ': 'D$_kDotBelow',
  'Ṇ': 'N$_kDotBelow',
};

final Map<String, String> _kComposedOctaveLetters = {
  for (final entry in _kPrecomposedOctaveLetters.entries)
    entry.value: entry.key,
};

extension SwaraNoteInfo on SwaraNote {
  /// Position counted from madhya Sa, e.g. -5 for mandra Pa.
  int get absolutePosition => swara.position + 12 * octave;

  double get ratio => swara.ratio * math.pow(2.0, octave);

  double get cents => centsForRatio(ratio);

  double frequencyFor(double saHz) => saHz * ratio;

  String get octaveMarks => octave > 0
      ? _kDotAbove * octave
      : octave < 0
      ? _kDotBelow * -octave
      : '';

  /// Display label such as `Ṡ`, `P̣`, `R2` or `Ṙ1`.
  String get label {
    final letterWithMarks = '${swara.letter.symbol}$octaveMarks';
    final letter = _kComposedOctaveLetters[letterWithMarks] ?? letterWithMarks;
    return '$letter${swara.variant ?? ''}';
  }

  String get telugu {
    final number = swara.variant;
    final suffix = number == null ? '' : _kSubscriptDigits[number];
    return '${swara.letter.telugu}$octaveMarks$suffix';
  }

  String get fullName {
    if (octave == 0) {
      return swara == Swara.s ? 'Adhara Shadjam' : swara.sthanaName;
    }
    final sthayi = switch (octave) {
      -1 => 'Mandra',
      1 => 'Tara',
      < -1 => 'Anumandra',
      _ => 'Atitara',
    };
    return '$sthayi ${swara.sthanaName}';
  }
}

/// Parses Carnatic notation tokens such as `S`, `R2`, `Ṡ`, `P̣`, `Ṇ3`, or
/// `S'`. Letters without a variant number resolve through [letters], which
/// is normally supplied by the session raga.
extension SwaraNotation on String {
  bool get isKarvai => trim() == ',';

  SwaraNote? toSwaraNote([
    Map<SwaraLetter, Swara> letters = kDefaultLetterSwaras,
  ]) {
    final decomposed = trim()
        .toUpperCase()
        .split('')
        .map((char) => _kPrecomposedOctaveLetters[char] ?? char)
        .join();
    final match = _kNotationPattern.firstMatch(decomposed);
    if (match == null) return null;

    final letter = SwaraLetter.values.firstWhere(
      (l) => l.symbol == match.group(1),
    );
    final marks = '${match.group(2)}${match.group(4)}${match.group(5)}';
    final octave =
        _count(marks, _kDotAbove) +
        _count(marks, "'") -
        _count(marks, _kDotBelow) -
        _count(marks, '.');

    final digit = match.group(3)!;
    final Swara? swara = digit.isEmpty
        ? letters[letter] ?? kDefaultLetterSwaras[letter]
        : swaraFor(letter, int.parse(digit));
    return swara == null ? null : SwaraNote(swara, octave);
  }
}

final RegExp _kNotationPattern = RegExp(
  '^([SRGMPDN])([$_kDotAbove$_kDotBelow]*)([1-3]?)([$_kDotAbove$_kDotBelow]*)'
  r"(['.]*)$",
);

int _count(String text, String char) => char.allMatches(text).length;

/// Parses space-separated notation into notes, throwing [FormatException]
/// for tokens that are not swaras.
List<SwaraNote> parseSwaraNotes(String notation) => [
  for (final token in notation.trim().split(RegExp(r'\s+')))
    if (token.isNotEmpty)
      token.toSwaraNote() ??
          (throw FormatException('Unknown swara "$token"', notation)),
];

String formatSwaraNotes(List<SwaraNote> notes) =>
    notes.map((note) => note.label).join(' ');
