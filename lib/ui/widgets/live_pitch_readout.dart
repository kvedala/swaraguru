import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

import '../../pitch/swara_identifier.dart';
import '../../studio/pitch_display.dart';
import '../../theme/swara_theme.dart';

String formatCents(num cents) {
  final rounded = cents.round();
  return rounded > 0 ? '+$rounded' : '$rounded';
}

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
        '$hz (${formatCents(pitch.centsOff)} cents from Swarasthana)'
            '${pitch.inRaga ? '' : ' • outside the raga'}',
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

/// Tuner-style needle showing how far the heard pitch is from the nearest
/// swarasthana, with the apasruti tolerance band highlighted.
class CentsMeter extends StatelessWidget {
  const CentsMeter({super.key, required this.centsOff, required this.active});

  final double centsOff;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: active
          ? '${formatCents(centsOff)} cents from swarasthana'
          : 'No pitch',
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: CustomPaint(
          painter: _CentsMeterPainter(
            centsOff: centsOff.clamp(-50.0, 50.0),
            active: active,
          ),
        ),
      ),
    );
  }
}

class _CentsMeterPainter extends CustomPainter {
  _CentsMeterPainter({required this.centsOff, required this.active});

  final double centsOff;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final barTop = 8.0;
    final barHeight = size.height - 24;
    double xFor(double cents) => (cents + 50) / 100 * size.width;

    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barTop, size.width, barHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(track, Paint()..color = SwaraColors.midnightBg);

    const tolerance = kApasrutiToleranceCents;
    canvas.drawRect(
      Rect.fromLTRB(
        xFor(-tolerance),
        barTop,
        xFor(tolerance),
        barTop + barHeight,
      ),
      Paint()..color = SwaraColors.emeraldMatch.withValues(alpha: 0.25),
    );
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = SwaraColors.borderGold,
    );

    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    for (final cents in const [-50, -25, 0, 25, 50]) {
      final x = xFor(cents.toDouble()).clamp(0.5, size.width - 0.5);
      canvas.drawLine(
        Offset(x, barTop + barHeight),
        Offset(x, barTop + barHeight + 4),
        tickPaint,
      );
      final text = TextPainter(
        text: TextSpan(
          text: cents == 0 ? '0' : formatCents(cents),
          style: const TextStyle(fontSize: 9, color: Colors.white54),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (x - text.width / 2).clamp(0.0, size.width - text.width);
      text.paint(canvas, Offset(left, barTop + barHeight + 4));
    }

    if (!active) return;
    final x = xFor(centsOff);
    final color = centsOff.abs() <= tolerance
        ? SwaraColors.emeraldMatch
        : SwaraColors.warmAmber;
    canvas.drawLine(
      Offset(x, barTop - 4),
      Offset(x, barTop + barHeight + 2),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CentsMeterPainter oldDelegate) =>
      oldDelegate.centsOff != centsOff || oldDelegate.active != active;
}
