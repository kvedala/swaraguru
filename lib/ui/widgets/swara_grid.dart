import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';

/// Adi tala kriya for each of its eight beats
/// (Laghu of 4 + Dhrutam of 2 + Dhrutam of 2).
String adiTalaKriya(int beat) => switch (beat) {
  1 => 'Clap (Laghu)',
  <= 4 => 'Finger ${beat - 1}',
  _ => beat.isOdd ? 'Clap (Dhrutam)' : 'Wave',
};

class AdiTalaBeatStrip extends StatelessWidget {
  const AdiTalaBeatStrip({super.key, required this.activeBeat});

  /// 1–8, or `null` when the transport is idle.
  final int? activeBeat;

  @override
  Widget build(BuildContext context) {
    final beat = activeBeat;
    final action = beat == null ? 'Adi tala' : adiTalaKriya(beat).split(' (').first;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 2,
          runSpacing: 4,
          children: [
            for (var number = 1; number <= 8; number++)
              _BeatChip(beat: number, isCurrent: beat == number),
          ],
        ),
        Text(action, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

class _BeatChip extends StatelessWidget {
  const _BeatChip({required this.beat, required this.isCurrent});

  final int beat;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final label = 'Beat $beat • ${adiTalaKriya(beat)}';
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        selected: isCurrent,
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minWidth: 20),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: isCurrent ? SwaraColors.royalGold : SwaraColors.midnightBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCurrent ? SwaraColors.brightGold : SwaraColors.borderGold,
            ),
          ),
          child: Text(
            '$beat',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0,
              fontWeight: FontWeight.bold,
              color: isCurrent ? SwaraColors.midnightBg : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

/// The lesson's swaras, colour-coded by their pitch evaluation.
class SwaraGrid extends StatefulWidget {
  const SwaraGrid({super.key, required this.controller});

  final StudioController controller;

  @override
  State<SwaraGrid> createState() => _SwaraGridState();
}

class _SwaraGridState extends State<SwaraGrid> {
  StudioController? _controller;
  List<LessonStep>? _steps;
  int? _stepsPerCycle;
  late SliverChildDelegate _cells;
  SliverChildDelegate? _rows;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final steps = controller.steps;
    final hasWrittenRows = steps.isNotEmpty && steps.first.startsRow;
    final beats = hasWrittenRows ? null : controller.activeLesson.talaBeatsForLayout;
    final stepsPerBeat = controller.kaalam.swarasPerBeat;
    final stepsPerCycle = beats == null
        ? null
        : math.min(beats, steps.length) * stepsPerBeat;
    // Keep the delegate stable on transport ticks so mounted cells can update
    // independently instead of rebuilding the entire visible grid.
    if (_controller != controller ||
        _steps != steps ||
        _stepsPerCycle != stepsPerCycle) {
      _controller = controller;
      _steps = steps;
      _stepsPerCycle = stepsPerCycle;
      Widget cell(int index) => _LiveSwaraCell(
        key: ValueKey(index),
        controller: controller,
        index: index,
        step: steps[index],
      );
      if (steps.isNotEmpty && (hasWrittenRows || stepsPerCycle != null)) {
        final boundaries = [
          0,
          if (hasWrittenRows)
            for (var i = 1; i < steps.length; i++)
              if (steps[i].startsRow) i,
          if (stepsPerCycle != null)
            for (var i = stepsPerCycle; i < steps.length; i += stepsPerCycle) i,
          steps.length,
        ];
        _rows = SliverChildBuilderDelegate(
          (_, row) {
            final start = boundaries[row];
            final groups = <({List<Widget> cells, bool glides})>[];
            for (var i = start; i < boundaries[row + 1]; i++) {
              if (i == start ||
                  (hasWrittenRows ? steps[i].startsCell : i % stepsPerBeat == 0)) {
                groups.add((cells: [], glides: false));
              }
              final group = groups.last;
              group.cells.add(cell(i));
              if (!group.glides && steps[i].glidesFromPrevious) {
                groups[groups.length - 1] = (cells: group.cells, glides: true);
              }
            }
            return _NotationRow(gapBefore: row == 0 ? 0 : 12, groups: groups);
          },
          childCount: boundaries.length - 1,
        );
      } else {
        _rows = null;
        _cells = SliverChildBuilderDelegate(
          (_, index) => cell(index),
          childCount: steps.length,
        );
      }
    }

    if (_rows case final rows?) return SliverList(delegate: rows);

    final size = _swaraCellSize(context);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: size.width,
        mainAxisExtent: size.height,
        crossAxisSpacing: _cellSpacing,
        mainAxisSpacing: _cellSpacing,
      ),
      delegate: _cells,
    );
  }
}

const _cellSpacing = 4.0;

Size _swaraCellSize(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  return Size(
    82 + (scaler.scale(13) - 13) * 5,
    15 + scaler.scale(17) + scaler.scale(12) * 2.5,
  );
}

class _NotationRow extends StatelessWidget {
  const _NotationRow({required this.gapBefore, required this.groups});

  final double gapBefore;
  final List<({List<Widget> cells, bool glides})> groups;

  static const _groupSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final size = _swaraCellSize(context);
    final grouped =
        groups.length > 1 && groups.any((group) => group.cells.length > 1);
    final spacing = grouped ? _groupSpacing : _cellSpacing;
    return Padding(
      padding: EdgeInsets.only(top: gapBefore),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = math.max(
            1,
            (width / (size.width + spacing)).ceil(),
          );
          final cellWidth =
              ((width - (columns - 1) * spacing) / columns).floorToDouble();
          Widget sized(Widget child) =>
              SizedBox(width: cellWidth, height: size.height, child: child);

          Widget groupWidget(({List<Widget> cells, bool glides}) group) {
            if (group.cells.length == 1) return sized(group.cells.single);
            final notes = Wrap(
              spacing: _cellSpacing,
              runSpacing: _cellSpacing,
              children: [for (final child in group.cells) sized(child)],
            );
            if (!group.glides) return notes;
            return Tooltip(
              message: 'Glide between swaras',
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: SwaraColors.cyanWave, width: 2),
                  ),
                ),
                child: notes,
              ),
            );
          }

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [for (final group in groups) groupWidget(group)],
          );
        },
      ),
    );
  }
}

typedef _CellState = (double saHz, bool active, StepPitchEvaluation? evaluation);

class _LiveSwaraCell extends StatefulWidget {
  const _LiveSwaraCell({
    super.key,
    required this.controller,
    required this.index,
    required this.step,
  });

  final StudioController controller;
  final int index;
  final LessonStep step;

  @override
  State<_LiveSwaraCell> createState() => _LiveSwaraCellState();
}

class _LiveSwaraCellState extends State<_LiveSwaraCell> {
  late _CellState _state;

  _CellState _read() => (
    widget.controller.saHz,
    widget.index == widget.controller.activeStepIndex,
    widget.controller.evaluationAt(widget.index),
  );

  void _update() {
    final next = _read();
    if (next != _state) setState(() => _state = next);
  }

  @override
  void initState() {
    super.initState();
    _state = _read();
    widget.controller.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant _LiveSwaraCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
    }
    _state = _read();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (saHz, active, evaluation) = _state;
    return SwaraCell(
      step: widget.step,
      saHz: saHz,
      isActive: active,
      evaluation: evaluation,
      onTap: () => widget.controller.previewStep(widget.index),
    );
  }
}

class SwaraCell extends StatelessWidget {
  const SwaraCell({
    super.key,
    required this.step,
    required this.saHz,
    required this.isActive,
    required this.evaluation,
    required this.onTap,
  });

  final LessonStep step;
  final double saHz;
  final bool isActive;
  final StepPitchEvaluation? evaluation;
  final VoidCallback onTap;

  static const _wrongSwaraText = Color(0xFFFDA4AF);

  @override
  Widget build(BuildContext context) {
    final note = step.note;
    final evaluation = this.evaluation;
    final statusColor = switch (evaluation?.status) {
      NoteMatchStatus.match => SwaraColors.emeraldMatch,
      NoteMatchStatus.apasruti => SwaraColors.warmAmber,
      NoteMatchStatus.wrongSwara => SwaraColors.crimsonRobes,
      NoteMatchStatus.noVoice => Colors.blueGrey,
      null => null,
    };
    final invalid = note == null && !step.isKarvai;
    final borderColor = isActive
        ? SwaraColors.brightGold
        : statusColor ??
              (invalid ? SwaraColors.crimsonRobes : SwaraColors.borderGold);
    final background = isActive
        ? SwaraColors.royalGold.withValues(alpha: 0.25)
        : statusColor?.withValues(alpha: 0.18) ?? SwaraColors.midnightBg;

    final String detail;
    var detailColor = SwaraColors.cyanWave;
    if (evaluation != null) {
      switch (evaluation.status) {
        case NoteMatchStatus.wrongSwara:
          detail = 'Sang ${evaluation.sung?.label ?? '?'}';
          detailColor = _wrongSwaraText;
        case NoteMatchStatus.noVoice:
          detail = 'No voice';
          detailColor = Colors.white54;
        case NoteMatchStatus.match:
          detail = 'Matched';
        case NoteMatchStatus.apasruti:
          detail = evaluation.centDeviation == 0
              ? 'Pitch drift'
              : evaluation.centDeviation > 0
              ? 'Too high'
              : 'Too low';
      }
    } else if (invalid) {
      detail = 'Unknown';
      detailColor = _wrongSwaraText;
    } else if (step.isKarvai) {
      detail = 'Karvai';
    } else {
      detail = '${note!.frequencyFor(saHz).round()} Hz';
    }

    return Tooltip(
      message: switch ((note, step.isKarvai)) {
        (final SwaraNote n, true) => 'Karvai — sustain ${n.fullName}',
        (final SwaraNote n, false) => n.fullName,
        (null, _) => 'Unrecognised swara "${step.token}"',
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isActive ? 2 : 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                step.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                step.lyric ?? (step.isKarvai ? '—' : note?.telugu ?? '?'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  color: SwaraColors.royalGold,
                ),
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: detailColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
