import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../studio/studio_controller.dart';
import '../../theme/swara_theme.dart';
import 'instrument_selector.dart';
import 'labels.dart';

const List<DroneChannel> _kPureChannels = [
  DroneChannel.sa,
  DroneChannel.ma1,
  DroneChannel.ma2,
  DroneChannel.pa,
  DroneChannel.ni3,
  DroneChannel.taraSa,
];

/// Shruti box configuration: instrument, mode, tuning preset, channel mix,
/// volume and fine tuning.
class DroneControls extends StatelessWidget {
  const DroneControls({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final drone = controller.drone;
    final saHz = controller.saHz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ControlLabel('Drone Instrument'),
        const SizedBox(height: 8),
        InstrumentSelector(
          selected: drone.instrument,
          onChanged: controller.setDroneInstrument,
        ),
        const SizedBox(height: 4),
        Text(
          drone.instrument.description,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
        const SizedBox(height: 16),
        SegmentedButton<DroneMode>(
          segments: const [
            ButtonSegment(
              value: DroneMode.pureSingleNote,
              icon: Icon(Icons.looks_one_rounded),
              label: Text('Pure Single Note'),
            ),
            ButtonSegment(
              value: DroneMode.multiNoteChord,
              icon: Icon(Icons.graphic_eq_rounded),
              label: Text('Multiple Notes'),
            ),
          ],
          selected: {drone.mode},
          onSelectionChanged: (selection) =>
              controller.setDroneMode(selection.first),
        ),
        const SizedBox(height: 16),
        if (drone.mode == DroneMode.pureSingleNote) ...[
          const ControlLabel('Select Isolated Pure Reference Swara:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final channel in _kPureChannels)
                ChoiceChip(
                  label: Text(
                    '${channel.label} '
                    '(${channel.note.frequencyFor(saHz).round()} Hz)',
                  ),
                  selected: drone.pureChannel == channel,
                  onSelected: (_) => controller.setPureChannel(channel),
                ),
            ],
          ),
        ] else ...[
          const ControlLabel('Tampura Tuning'),
          const SizedBox(height: 8),
          _PresetChips(controller: controller),
          const SizedBox(height: 12),
          const ControlLabel('Multi-Note Tampura Channels (Toggle & Mix):'),
          const SizedBox(height: 8),
          for (final channel in DroneChannel.values)
            _ChannelMixer(
              channel: channel,
              level: drone.levelOf(channel),
              frequencyHz: channel.note.frequencyFor(saHz),
              onChanged: (level) => controller.setChannelLevel(channel, level),
            ),
        ],
        const SizedBox(height: 12),
        const ControlLabel('Master Shruti Volume & Fine Tuning (Cents)'),
        Slider(
          value: drone.volume,
          min: 0.05,
          max: 1.0,
          label: 'Volume ${(100 * drone.volume).round()}%',
          onChanged: controller.setDroneVolume,
        ),
        Slider(
          value: controller.fineTuneCents,
          min: -50,
          max: 50,
          divisions: 100,
          label: '${controller.fineTuneCents.round()} cents',
          onChanged: controller.setFineTune,
        ),
        Text(
          'Sa = ${saHz.toStringAsFixed(2)} Hz '
          '(${controller.fineTuneCents.round()} cents)',
          style: const TextStyle(fontSize: 11, color: SwaraColors.cyanWave),
        ),
      ],
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final suggested = controller.suggestedDronePreset;
    final raga = controller.raga;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in DronePreset.values)
              ActionChip(
                avatar: preset == suggested
                    ? const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: SwaraColors.brightGold,
                      )
                    : null,
                label: Text(preset.label),
                tooltip: preset.description,
                onPressed: () => controller.applyDronePreset(preset),
              ),
          ],
        ),
        if (suggested != DronePreset.pa) ...[
          const SizedBox(height: 6),
          Text(
            '${raga.name} omits Panchamam — ${suggested.label} '
            '(${suggested.description}) suits it best.',
            style: const TextStyle(fontSize: 11, color: SwaraColors.warmAmber),
          ),
        ],
      ],
    );
  }
}

class _ChannelMixer extends StatelessWidget {
  const _ChannelMixer({
    required this.channel,
    required this.level,
    required this.frequencyHz,
    required this.onChanged,
  });

  final DroneChannel channel;
  final double level;
  final double frequencyHz;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: SwaraColors.midnightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: level > 0.05 ? SwaraColors.royalGold : Colors.white12,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${channel.label} • ${channel.note.fullName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${frequencyHz.toStringAsFixed(1)} Hz '
                  '(${(level * 100).round()}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SwaraColors.cyanWave,
                  ),
                ),
              ],
            ),
            Slider(value: level, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
