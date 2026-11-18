// SwaraGuru: Carnatic Studio
//
// lib/
//   models/  json_serializable data: swaras, ragas, lessons, shruti, drone
//   pitch/   YIN pitch detection, microphone source, swara identification
//   audio/   tampura / harmonium / piano synthesis (Web Audio)
//   studio/  StudioController session state
//   theme/   brand colours and ThemeData
//   ui/      adaptive scaffold, screens, drawers, dialogs and widgets

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'audio/metronome_audio.dart';
import 'models/carnatic_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (MetronomeAudio.isSupported) await MetronomeAudio.initialise();
  final catalog = await CarnaticCatalog.load(rootBundle);
  runApp(SwaraGuruApp(catalog: catalog));
}
