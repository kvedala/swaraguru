import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

import '../../studio/pitch_display.dart';
import '../../theme/swara_theme.dart';

/// Compact swara badge plus description of the latest reference or heard
/// pitch. Rebuilds only when [display] changes.
class LivePitchReadout extends StatelessWidget {
  const LivePitchReadout({
    super.key,
    required this.display,
    this.idleHint =
        'Tap any Swara cell, press "Sing & Match Swaras" or turn on Listen',
  });

  final ValueListenable<PitchDisplay> display;
  final String idleHint;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PitchDisplay>(
      valueListenable: display,
      builder: (context, pitch, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwaraBadge(label: pitch.label, inRaga: pitch.inRaga),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pitch.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _describe(pitch),
                  style: TextStyle(
                    fontSize: 12,
                    color: pitch.inRaga
                        ? SwaraColors.cyanWave
                        : SwaraColors.warmAmber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _describe(PitchDisplay pitch) {
    if (!pitch.hasPitch) {
      return identical(pitch, PitchDisplay.idle)
          ? idleHint
          : 'Waiting for a steady pitch…';
    }
    final hz = '${pitch.frequencyHz.toStringAsFixed(1)} Hz';
    return switch (pitch.source) {
      PitchDisplaySource.reference => '$hz • reference swarasthana',
      PitchDisplaySource.voice =>
        '$hz${pitch.inRaga ? '' : ' • outside the raga'}',
      PitchDisplaySource.idle => hz,
    };
  }
}

class SwaraBadge extends StatelessWidget {
  const SwaraBadge({
    super.key,
    required this.label,
    this.inRaga = true,
    this.size = 54,
  });

  final String label;
  final bool inRaga;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SwaraColors.midnightBg,
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(
          color: inRaga ? SwaraColors.royalGold : SwaraColors.warmAmber,
          width: inRaga ? 1 : 2,
        ),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w900,
              color: SwaraColors.brightGold,
            ),
          ),
        ),
      ),
    );
  }
}
