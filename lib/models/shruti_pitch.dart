import 'package:json_annotation/json_annotation.dart';

part 'shruti_pitch.g.dart';

/// A base Sa (Adhara Shadjam) choice from the harmonium kattai scale.
@JsonSerializable()
class ShrutiPitch {
  const ShrutiPitch({
    required this.id,
    required this.kattai,
    required this.frequencyHz,
  });

  factory ShrutiPitch.fromJson(Map<String, dynamic> json) =>
      _$ShrutiPitchFromJson(json);

  /// Western pitch name, such as `C#`.
  final String id;

  /// Kattai (harmonium key) number, e.g. 1.5 for C#.
  final double kattai;
  final double frequencyHz;

  Map<String, dynamic> toJson() => _$ShrutiPitchToJson(this);

  @override
  bool operator ==(Object other) => other is ShrutiPitch && other.id == id;

  @override
  int get hashCode => id.hashCode;

  String get label => id;

  String get kattaiName {
    final whole = kattai.truncate();
    return '$whole${kattai > whole ? '½' : ''} Kattai';
  }
}

/// Base Sa pitches from A2 (6 Kattai) through G#3 (5½ Kattai), A4 = 440 Hz.
const List<ShrutiPitch> kShrutiPitches = [
  ShrutiPitch(id: 'A', kattai: 6, frequencyHz: 110.00),
  ShrutiPitch(id: 'A#', kattai: 6.5, frequencyHz: 116.54),
  ShrutiPitch(id: 'B', kattai: 7, frequencyHz: 123.47),
  ShrutiPitch(id: 'C', kattai: 1, frequencyHz: 130.81),
  ShrutiPitch(id: 'C#', kattai: 1.5, frequencyHz: 138.59),
  ShrutiPitch(id: 'D', kattai: 2, frequencyHz: 146.83),
  ShrutiPitch(id: 'D#', kattai: 2.5, frequencyHz: 155.56),
  ShrutiPitch(id: 'E', kattai: 3, frequencyHz: 164.81),
  ShrutiPitch(id: 'F', kattai: 4, frequencyHz: 174.61),
  ShrutiPitch(id: 'F#', kattai: 4.5, frequencyHz: 185.00),
  ShrutiPitch(id: 'G', kattai: 5, frequencyHz: 196.00),
  ShrutiPitch(id: 'G#', kattai: 5.5, frequencyHz: 207.65),
];

/// C# (1½ Kattai).
final ShrutiPitch kDefaultShruti = kShrutiPitches.firstWhere(
  (pitch) => pitch.id == 'C#',
);
