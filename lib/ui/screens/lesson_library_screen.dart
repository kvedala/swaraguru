import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../theme/swara_theme.dart';

enum _Category {
  sarali('Sarali Varisai', Icons.trending_up_rounded),
  janta('Janta Varisai', Icons.repeat_rounded),
  dhatu('Dhatu Varisai', Icons.swap_vert_rounded),
  geetams('Geetams', Icons.music_note_rounded),
  other('Custom Songs & Scales', Icons.queue_music_rounded);

  const _Category(this.label, this.icon);

  final String label;
  final IconData icon;

  static _Category forLesson(CarnaticLesson lesson) => switch (lesson.group) {
    'Sarali Varisai' => sarali,
    'Janta Varisai' => janta,
    'Dhatu Varisai' => dhatu,
    'Geetam' || 'Pillari Geetham' => geetams,
    _ => other,
  };
}

class LessonLibraryScreen extends StatefulWidget {
  const LessonLibraryScreen({
    super.key,
    required this.lessons,
    required this.activeLesson,
    required this.onSelectLesson,
    required this.onAddCustomLesson,
  });

  final List<CarnaticLesson> lessons;
  final CarnaticLesson activeLesson;
  final ValueChanged<CarnaticLesson> onSelectLesson;
  final VoidCallback onAddCustomLesson;

  @override
  State<LessonLibraryScreen> createState() => _LessonLibraryScreenState();
}

class _LessonLibraryScreenState extends State<LessonLibraryScreen> {
  _Category? _category;

  @override
  Widget build(BuildContext context) {
    final grouped = <_Category, List<CarnaticLesson>>{
      for (final category in _Category.values) category: [],
    };
    for (final lesson in widget.lessons) {
      grouped[_Category.forLesson(lesson)]!.add(lesson);
    }

    final category = _category;
    final lessons = grouped[category] ?? [];
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (category == null) ...[
              const Text('Choose a category to find a lesson.'),
              const SizedBox(height: 12),
              for (final entry in grouped.entries)
                if (entry.value.isNotEmpty)
                  Card(
                    child: ListTile(
                      leading: Icon(entry.key.icon, color: SwaraColors.brightGold),
                      title: Text(entry.key.label),
                      subtitle: Text(
                        '${entry.value.length} '
                        '${entry.value.length == 1 ? 'lesson' : 'lessons'}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => setState(() => _category = entry.key),
                    ),
                  ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: widget.onAddCustomLesson,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add custom song'),
                ),
              ),
            ] else ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => _category = null),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('All categories'),
                ),
              ),
              Text(category.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final lesson in lessons)
                    if (lesson.combo case final combo?)
                      Tooltip(
                        message: lesson.title,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: lesson.id == widget.activeLesson.id
                                ? SwaraColors.royalGold.withValues(alpha: 0.18)
                                : null,
                          ),
                          onPressed: () => widget.onSelectLesson(lesson),
                          child: Text('Combo $combo'),
                        ),
                      ),
                ],
              ),
              for (final lesson in lessons)
                if (lesson.combo == null)
                  Card(
                    child: ListTile(
                      title: Text(lesson.title),
                      subtitle: Text(lesson.raga),
                      selected: lesson.id == widget.activeLesson.id,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => widget.onSelectLesson(lesson),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
