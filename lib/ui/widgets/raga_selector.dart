import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../theme/swara_theme.dart';

/// Searchable raga picker covering all melakartas and bundled janya ragas.
/// Typing filters by name, alias (e.g. "Kalyani") or melakarta number.
class RagaSelector extends StatelessWidget {
  const RagaSelector({
    super.key,
    required this.ragas,
    required this.selected,
    required this.onSelected,
    this.width = 300,
    this.label = 'Session Raga',
  });

  final List<Raga> ragas;
  final Raga selected;
  final ValueChanged<Raga> onSelected;
  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<Raga>(
      // Re-create when the raga changes elsewhere so the field text follows.
      key: ValueKey('raga-${selected.name}'),
      width: width,
      menuHeight: 360,
      initialSelection: selected,
      label: Text(label),
      leadingIcon: const Icon(Icons.library_music_rounded),
      enableFilter: true,
      requestFocusOnTap: true,
      filterCallback: (entries, filter) => [
        for (final entry in entries)
          if (entry.value.matchesQuery(filter)) entry,
      ],
      onSelected: (raga) {
        if (raga != null) onSelected(raga);
      },
      dropdownMenuEntries: [
        for (final raga in ragas)
          DropdownMenuEntry(
            value: raga,
            label: raga.name,
            trailingIcon: Text(
              raga.isMelakarta
                  ? 'Mela ${raga.melakarta}'
                  : 'Janya ${raga.parentMelakarta ?? ''}'.trim(),
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ),
      ],
    );
  }
}

/// Compact arohanam / avarohanam summary of a raga.
class RagaScaleSummary extends StatelessWidget {
  const RagaScaleSummary({super.key, required this.raga});

  final Raga raga;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: SwaraColors.royalGold,
    );
    const notesStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${raga.name} • ${raga.classification}'
          '${raga.aliases.isEmpty ? '' : ' • also ${raga.aliases.join(', ')}'}',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Arohanam  ', style: labelStyle),
              TextSpan(
                text: formatSwaraNotes(raga.arohanam),
                style: notesStyle,
              ),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Avarohanam  ', style: labelStyle),
              TextSpan(
                text: formatSwaraNotes(raga.avarohanam),
                style: notesStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
