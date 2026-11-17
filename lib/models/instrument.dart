import 'package:json_annotation/json_annotation.dart';

/// Timbre used to render the drone or played swaras.
@JsonEnum()
enum SwaraInstrument { tampura, harmonium, piano }

extension SwaraInstrumentInfo on SwaraInstrument {
  String get label => switch (this) {
    SwaraInstrument.tampura => 'Tampura',
    SwaraInstrument.harmonium => 'Harmonium',
    SwaraInstrument.piano => 'Piano',
  };

  String get description => switch (this) {
    SwaraInstrument.tampura =>
      'Plucked strings with a buzzing jawari bridge and long decay.',
    SwaraInstrument.harmonium =>
      'Sustained reed tone with a slightly detuned second reed.',
    SwaraInstrument.piano =>
      'Struck strings with a bright attack that fades naturally.',
  };

  /// Whether a drone on this instrument is re-plucked rather than sustained.
  bool get isPlucked => this != SwaraInstrument.harmonium;
}
