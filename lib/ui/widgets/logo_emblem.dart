import 'package:material_ui/material_ui.dart';

import '../../theme/swara_theme.dart';

/// Renders the custom SwaraGuru App Logo Emblem inspired by your uploaded icon:
/// Rounded dark-indigo badge with double gold border, glowing golden waveform on left,
/// cyan microphone + soundwave on right, and seated Veena artist in the center.
class SwaraGuruLogoEmblem extends StatelessWidget {
  final double size;
  final bool showTitle;

  const SwaraGuruLogoEmblem({
    super.key,
    this.size = 56,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: const RadialGradient(
          colors: [Color(0xFF282E54), Color(0xFF101326)],
          radius: 0.85,
        ),
        border: Border.all(color: SwaraColors.royalGold, width: size * 0.035),
        boxShadow: [
          BoxShadow(
            color: SwaraColors.royalGold.withValues(alpha: 0.25),
            blurRadius: size * 0.25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _VeenaLogoPainter(),
        child: showTitle
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: size * 0.06),
                  child: Text(
                    'SwaraGuru',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: size * 0.14,
                      fontWeight: FontWeight.bold,
                      color: SwaraColors.brightGold,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _VeenaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Left Golden Soundwave Bars
    final goldWavePaint = Paint()
      ..color = SwaraColors.warmAmber
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    final waveHeights = [0.08, 0.18, 0.28, 0.14, 0.22];
    for (int i = 0; i < waveHeights.length; i++) {
      final x = w * (0.14 + i * 0.045);
      final halfH = h * waveHeights[i] * 0.5;
      canvas.drawLine(
        Offset(x, h * 0.45 - halfH),
        Offset(x, h * 0.45 + halfH),
        goldWavePaint,
      );
    }

    // 2. Right Cyan Voice Analysis Wave
    final cyanPaint = Paint()
      ..color = SwaraColors.cyanWave
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    final cyanHeights = [0.16, 0.26, 0.12, 0.20];
    for (int i = 0; i < cyanHeights.length; i++) {
      final x = w * (0.72 + i * 0.045);
      final halfH = h * cyanHeights[i] * 0.5;
      canvas.drawLine(
        Offset(x, h * 0.48 - halfH),
        Offset(x, h * 0.48 + halfH),
        cyanPaint,
      );
    }

    // 3. Seated Artist Silhouette & Saraswati Veena Diagonal Neck
    final bodyPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;

    // Head silhouette
    canvas.drawCircle(Offset(w * 0.50, h * 0.28), w * 0.075, bodyPaint);

    // Veena Gourd (Kudam) bottom-left
    final gourdPaint = Paint()
      ..shader = const LinearGradient(
        colors: [SwaraColors.brightGold, Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(w * 0.24, h * 0.48, w * 0.28, h * 0.28));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.37, h * 0.62),
        width: w * 0.26,
        height: h * 0.22,
      ),
      gourdPaint,
    );

    // Veena Dandi (Neck) diagonal to top-right
    final neckPaint = Paint()
      ..color = SwaraColors.royalGold
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.36, h * 0.62),
      Offset(w * 0.74, h * 0.26),
      neckPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
