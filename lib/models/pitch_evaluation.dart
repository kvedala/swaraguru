import 'package:json_annotation/json_annotation.dart';

import 'swara.dart';

part 'pitch_evaluation.g.dart';

@JsonEnum()
enum NoteMatchStatus { match, apasruti, wrongSwara, noVoice }

/// One fundamental-frequency estimate from the pitch detector.
@JsonSerializable()
class PitchReading {
  const PitchReading({
    required this.frequencyHz,
    required this.clarity,
    required this.rms,
  });

  factory PitchReading.fromJson(Map<String, dynamic> json) =>
      _$PitchReadingFromJson(json);

  final double frequencyHz;

  /// Confidence in the estimate, from 0 (noise) to 1 (pure periodic tone).
  final double clarity;

  /// Signal level of the analysed frame.
  final double rms;

  Map<String, dynamic> toJson() => _$PitchReadingToJson(this);
}

/// A detected pitch named as the nearest swarasthana for the session raga.
@JsonSerializable()
class IdentifiedSwara {
  const IdentifiedSwara({
    required this.note,
    required this.frequencyHz,
    required this.centsOff,
    required this.inRaga,
  });

  factory IdentifiedSwara.fromJson(Map<String, dynamic> json) =>
      _$IdentifiedSwaraFromJson(json);

  final SwaraNote note;
  final double frequencyHz;

  /// Deviation from the ideal swarasthana, between -50 and +50 cents.
  final double centsOff;

  /// Whether the swara belongs to the session raga.
  final bool inRaga;

  Map<String, dynamic> toJson() => _$IdentifiedSwaraToJson(this);
}

/// Result of comparing a sung step with the expected swara.
@JsonSerializable()
class StepPitchEvaluation {
  const StepPitchEvaluation({
    required this.stepIndex,
    required this.expected,
    required this.expectedFreqHz,
    required this.status,
    required this.message,
    this.sung,
    this.sungFreqHz,
    this.centDeviation = 0,
  });

  factory StepPitchEvaluation.fromJson(Map<String, dynamic> json) =>
      _$StepPitchEvaluationFromJson(json);

  final int stepIndex;
  final SwaraNote expected;
  final double expectedFreqHz;
  final SwaraNote? sung;
  final double? sungFreqHz;
  final int centDeviation;
  final NoteMatchStatus status;
  final String message;

  Map<String, dynamic> toJson() => _$StepPitchEvaluationToJson(this);
}
