import 'package:material_ui/material_ui.dart';

import 'audio/metronome_audio.dart';
import 'audio/swara_audio.dart';
import 'models/carnatic_catalog.dart';
import 'pitch/pitch_source.dart';
import 'theme/swara_theme.dart';
import 'ui/adaptive_scaffold.dart';

class SwaraGuruApp extends StatelessWidget {
  const SwaraGuruApp({
    super.key,
    required this.catalog,
    this.audio,
    this.pitchSource,
    this.metronome,
  });

  final CarnaticCatalog catalog;
  final SwaraAudio? audio;
  final PitchSource? pitchSource;
  final MetronomeAudio? metronome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwaraGuru • Carnatic Studio',
      debugShowCheckedModeBanner: false,
      theme: buildSwaraTheme(),
      home: SwaraGuruAdaptiveScaffold(
        catalog: catalog,
        audio: audio,
        pitchSource: pitchSource,
        metronome: metronome,
      ),
    );
  }
}
