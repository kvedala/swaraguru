import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../theme/swara_theme.dart';
import 'logo_emblem.dart';

/// Renders the widescreen SwaraGuru Hero Banner inspired by your attached banner:
/// Deep midnight indigo backdrop, ornate gold mandala corners, flowing cyan acoustic wave
/// with Telugu/Sanskrit swara script (స రి గ మ ప ద ని), gold serif title, and the Veena logo.
class SwaraGuruHeroBanner extends StatelessWidget {
  final ShrutiPitch activeShruti;
  final double saHz;
  final Raga raga;
  final bool dronePlaying;
  final String droneSummary;
  final VoidCallback onToggleDrone;
  final VoidCallback onOpenShrutiDrawer;

  const SwaraGuruHeroBanner({
    super.key,
    required this.activeShruti,
    required this.saHz,
    required this.raga,
    required this.dronePlaying,
    required this.droneSummary,
    required this.onToggleDrone,
    required this.onOpenShrutiDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1329), Color(0xFF171E3C), Color(0xFF0B0E1D)],
        ),
        border: Border.all(
          color: SwaraColors.royalGold.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _MandalaWaveBannerPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                // Left: Brand Typography + Tagline
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SwaraGuruLogoEmblem(size: 72),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SwaraGuru',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: SwaraColors.brightGold,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CARNATIC STUDIO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3.2,
                              color: SwaraColors.royalGold.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Learn Carnatic Music • ',
                                  style: TextStyle(
                                    color: SwaraColors.brightGold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Voice Analysis • ',
                                  style: TextStyle(color: SwaraColors.cyanWave),
                                ),
                                TextSpan(
                                  text: 'Interactive Practice',
                                  style: TextStyle(
                                    color: SwaraColors.brightGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Right: Active Shruti Status Pill & Quick Controls
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0B0E1D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: SwaraColors.royalGold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADHARA SA: ${activeShruti.label} • '
                            '${activeShruti.kattaiName} '
                            '(${saHz.toStringAsFixed(2)} Hz)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: SwaraColors.royalGold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Raga: ${raga.name} (${raga.classification})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: SwaraColors.brightGold,
                            ),
                          ),
                          Text(
                            'Shruti Box: $droneSummary',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: SwaraColors.cyanWave,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: onToggleDrone,
                        style: FilledButton.styleFrom(
                          backgroundColor: dronePlaying
                              ? SwaraColors.royalGold
                              : const Color(0xFF252D4D),
                          foregroundColor: dronePlaying
                              ? const Color(0xFF0B0E1D)
                              : SwaraColors.brightGold,
                        ),
                        icon: Icon(
                          dronePlaying ? Icons.pause_circle : Icons.play_circle,
                          size: 18,
                        ),
                        label: Text(
                          dronePlaying ? 'Stop Shruti' : 'Play Shruti',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Configure Pure vs Multi-Note Shruti Drone',
                        onPressed: onOpenShrutiDrawer,
                        icon: const Icon(
                          Icons.tune,
                          color: SwaraColors.royalGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MandalaWaveBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mandalaPaint = Paint()
      ..color = SwaraColors.royalGold.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Ornate concentric mandala rings in top-left and bottom-right corners
    for (int r = 1; r <= 5; r++) {
      canvas.drawCircle(Offset(0, 0), r * 22.0, mandalaPaint);
      canvas.drawCircle(
        Offset(size.width, size.height),
        r * 26.0,
        mandalaPaint,
      );
    }

    // Flowing cyan wave across the banner
    final wavePaint = Paint()
      ..color = SwaraColors.cyanWave.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.20,
      size.width * 0.55,
      size.height * 0.95,
      size.width,
      size.height * 0.45,
    );
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
