import 'package:material_ui/material_ui.dart';

import '../../models/instrument.dart';

extension SwaraInstrumentIcon on SwaraInstrument {
  IconData get icon => switch (this) {
    SwaraInstrument.tampura => Icons.queue_music_rounded,
    SwaraInstrument.harmonium => Icons.piano_rounded,
    SwaraInstrument.piano => Icons.piano_outlined,
  };
}

/// Segmented picker for tampura, harmonium or piano rendering.
class InstrumentSelector extends StatelessWidget {
  const InstrumentSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SwaraInstrument selected;
  final ValueChanged<SwaraInstrument> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SwaraInstrument>(
      showSelectedIcon: false,
      segments: [
        for (final instrument in SwaraInstrument.values)
          ButtonSegment(
            value: instrument,
            icon: Icon(instrument.icon, size: 18),
            label: Text(instrument.label),
            tooltip: instrument.description,
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
