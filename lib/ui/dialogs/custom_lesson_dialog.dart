import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
import '../widgets/raga_selector.dart';

Future<void> showCustomLessonDialog(
  BuildContext context,
  StudioController controller,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => CustomLessonDialog(controller: controller),
  );
}

/// Collects a title, raga and swara notation for a custom lesson.
class CustomLessonDialog extends StatefulWidget {
  const CustomLessonDialog({super.key, required this.controller});

  final StudioController controller;

  @override
  State<CustomLessonDialog> createState() => _CustomLessonDialogState();
}

class _CustomLessonDialogState extends State<CustomLessonDialog> {
  final _title = TextEditingController(text: 'Custom Varnam / Geetham');
  final _notation = TextEditingController(
    text: 'S R G M P D N Ṡ Ṡ N D P M G R S',
  );
  late Raga _raga = widget.controller.raga;
  String? _notationError;

  @override
  void dispose() {
    _title.dispose();
    _notation.dispose();
    super.dispose();
  }

  void _submit() {
    final tokens = tokenizeNotation(_notation.text);
    final invalid = CarnaticLesson(
      id: 'draft',
      group: '',
      title: '',
      raga: _raga.name,
      swaras: tokens,
    ).invalidTokens;
    final error = tokens.isEmpty
        ? 'Enter at least one swara.'
        : invalid.isNotEmpty
        ? 'Unrecognised: ${invalid.toSet().join(', ')}'
        : null;
    if (error != null) {
      setState(() => _notationError = error);
      return;
    }
    widget.controller.addCustomLesson(
      title: _title.text,
      raga: _raga,
      tokens: tokens,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SwaraColors.indigoSurface,
      title: const Text(
        'Add Custom Swara Sequence / Song',
        style: TextStyle(color: SwaraColors.brightGold, fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Song / Varisai Title',
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) => RagaSelector(
                  ragas: widget.controller.catalog.sortedRagas,
                  selected: _raga,
                  label: 'Raga',
                  width: constraints.maxWidth,
                  onSelected: (raga) => setState(() => _raga = raga),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notation,
                maxLines: 3,
                onChanged: (_) {
                  if (_notationError != null) {
                    setState(() => _notationError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Swaras (space-separated: S R G M P D N Ṡ)',
                  helperText:
                      'Plain letters follow the raga. Use R1/G2 etc. to '
                      'force a swarasthana, Ṡ or S\' for tara sthayi, '
                      'Ṇ or N. for mandra, and "," for karvai.',
                  helperMaxLines: 3,
                  errorText: _notationError,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Load & Practice')),
      ],
    );
  }
}
