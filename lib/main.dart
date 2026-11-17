// ============================================================================
// SwaraGuru: Carnatic Studio — Complete Reactive Flutter Application
// ============================================================================
// • Multi-Platform Adaptive UI: Mobile (<600px), Tablet (600–1024px), Desktop/Web (>=1024px)
// • Brand Theme: Midnight Indigo (#0D1021), Ornate Gold (#E5B869), Cyan Voice Wave (#38BDF8)
// • Custom Vector Artwork: SwaraGuruLogoEmblem & SwaraGuruHeroBanner (Mandala + Veena + Mic)
// • Complete Base "Sa" Selector: C, C#, D, D#, E, F, F#, G, G#, A, A#, B, B#
// • Kaalam Tempo Engine: Tempo 1, 2, 3, 4 (1, 2, 4, 8 Swaras/Beat in Adi Tala)
// • Pure Single-Note vs. Multi-Note Shruti Drone Engine (Web Audio Synthesis)
// • Real-Time Pitch Detection, Vocal Simulation & Swarasthana Mistake Diagnostics
// ============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'shruti_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SwaraGuruFlutterApp());
}

// ============================================================================
// 1. BRAND THEME & COLOR TOKENS (FROM ATTACHED SWARAGURU LOGO & BANNER)
// ============================================================================

class SwaraColors {
  static const Color midnightBg = Color(0xFF0B0E1D);
  static const Color indigoSurface = Color(0xFF13182E);
  static const Color indigoCard = Color(0xFF19203B);
  static const Color royalGold = Color(0xFFE5B869);
  static const Color brightGold = Color(0xFFFDE68A);
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color cyanWave = Color(0xFF38BDF8);
  static const Color crimsonRobes = Color(0xFFE11D48);
  static const Color emeraldMatch = Color(0xFF10B981);
  static const Color borderGold = Color(0x44E5B869);
}

class SwaraGuruFlutterApp extends StatelessWidget {
  const SwaraGuruFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwaraGuru • Carnatic Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SwaraColors.midnightBg,
        colorScheme: const ColorScheme.dark(
          primary: SwaraColors.royalGold,
          onPrimary: Color(0xFF0B0E1D),
          secondary: SwaraColors.cyanWave,
          onSecondary: Color(0xFF0B0E1D),
          tertiary: SwaraColors.warmAmber,
          error: SwaraColors.crimsonRobes,
          surface: SwaraColors.indigoSurface,
          onSurface: Color(0xFFF8FAFC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: SwaraColors.indigoSurface,
          foregroundColor: SwaraColors.brightGold,
          elevation: 0,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: SwaraColors.indigoSurface,
        ),
        cardTheme: CardThemeData(
          color: SwaraColors.indigoCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: SwaraColors.borderGold, width: 1),
          ),
        ),
      ),
      home: const SwaraGuruAdaptiveScaffold(),
    );
  }
}

// ============================================================================
// 2. CARNATIC MUSIC DATA MODELS: SHRUTI, SWARASTHANAS, KAALAM & REPERTOIRE
// ============================================================================

class ShrutiPitch {
  final String id;
  final String label;
  final String kattaiName;
  final double frequencyHz;

  const ShrutiPitch({
    required this.id,
    required this.label,
    required this.kattaiName,
    required this.frequencyHz,
  });
}

const List<ShrutiPitch> kShrutiList = [
  ShrutiPitch(
    id: 'C',
    label: 'C',
    kattaiName: '1 Kattai (White 1)',
    frequencyHz: 261.63,
  ),
  ShrutiPitch(
    id: 'C#',
    label: 'C#',
    kattaiName: '1½ Kattai (Black 1)',
    frequencyHz: 277.18,
  ),
  ShrutiPitch(
    id: 'D',
    label: 'D',
    kattaiName: '2 Kattai (White 2)',
    frequencyHz: 293.66,
  ),
  ShrutiPitch(
    id: 'D#',
    label: 'D#',
    kattaiName: '2½ Kattai (Black 2)',
    frequencyHz: 311.13,
  ),
  ShrutiPitch(
    id: 'E',
    label: 'E',
    kattaiName: '3 Kattai (White 3)',
    frequencyHz: 329.63,
  ),
  ShrutiPitch(
    id: 'F',
    label: 'F',
    kattaiName: '4 Kattai (White 4)',
    frequencyHz: 349.23,
  ),
  ShrutiPitch(
    id: 'F#',
    label: 'F#',
    kattaiName: '4½ Kattai (Black 3)',
    frequencyHz: 369.99,
  ),
  ShrutiPitch(
    id: 'G',
    label: 'G',
    kattaiName: '5 Kattai (White 5)',
    frequencyHz: 392.00,
  ),
  ShrutiPitch(
    id: 'G#',
    label: 'G#',
    kattaiName: '5½ Kattai (Black 4)',
    frequencyHz: 415.30,
  ),
  ShrutiPitch(
    id: 'A',
    label: 'A',
    kattaiName: '6 Kattai (White 6)',
    frequencyHz: 440.00,
  ),
  ShrutiPitch(
    id: 'A#',
    label: 'A#',
    kattaiName: '6½ Kattai (Black 5)',
    frequencyHz: 466.16,
  ),
  ShrutiPitch(
    id: 'B',
    label: 'B',
    kattaiName: '7 Kattai (White 7)',
    frequencyHz: 493.88,
  ),
  ShrutiPitch(
    id: 'B#',
    label: 'B#',
    kattaiName: 'Enharmonic 1 Kattai (C)',
    frequencyHz: 523.25,
  ),
];

class SwarasthanaSpec {
  final String code;
  final String shortLabel;
  final String teluguScript;
  final String fullName;
  final int centsFromSa;

  const SwarasthanaSpec({
    required this.code,
    required this.shortLabel,
    required this.teluguScript,
    required this.fullName,
    required this.centsFromSa,
  });

  double get ratio => math.pow(2.0, centsFromSa / 1200.0).toDouble();
}

const List<SwarasthanaSpec> kSwarasthanaTable = [
  SwarasthanaSpec(
    code: 'P_low',
    shortLabel: 'P̣',
    teluguScript: 'ప',
    fullName: 'Mandra Panchamam',
    centsFromSa: -500,
  ),
  SwarasthanaSpec(
    code: 'N3_low',
    shortLabel: 'Ṇ3',
    teluguScript: 'ని',
    fullName: 'Mandra Kakali Nishadam',
    centsFromSa: -100,
  ),
  SwarasthanaSpec(
    code: 'S',
    shortLabel: 'S',
    teluguScript: 'స',
    fullName: 'Adhara Shadjam',
    centsFromSa: 0,
  ),
  SwarasthanaSpec(
    code: 'R1',
    shortLabel: 'R',
    teluguScript: 'రి',
    fullName: 'Shuddha Rishabham',
    centsFromSa: 100,
  ),
  SwarasthanaSpec(
    code: 'R2',
    shortLabel: 'R2',
    teluguScript: 'రి₂',
    fullName: 'Chatushruti Rishabham',
    centsFromSa: 200,
  ),
  SwarasthanaSpec(
    code: 'G2',
    shortLabel: 'G2',
    teluguScript: 'గ₂',
    fullName: 'Sadharana Gandharam',
    centsFromSa: 300,
  ),
  SwarasthanaSpec(
    code: 'G3',
    shortLabel: 'G',
    teluguScript: 'గ',
    fullName: 'Antara Gandharam',
    centsFromSa: 400,
  ),
  SwarasthanaSpec(
    code: 'M1',
    shortLabel: 'M',
    teluguScript: 'మ',
    fullName: 'Shuddha Madhyamam',
    centsFromSa: 500,
  ),
  SwarasthanaSpec(
    code: 'M2',
    shortLabel: 'M2',
    teluguScript: 'మ₂',
    fullName: 'Prati Madhyamam',
    centsFromSa: 600,
  ),
  SwarasthanaSpec(
    code: 'P',
    shortLabel: 'P',
    teluguScript: 'ప',
    fullName: 'Panchamam',
    centsFromSa: 700,
  ),
  SwarasthanaSpec(
    code: 'D1',
    shortLabel: 'D',
    teluguScript: 'ద',
    fullName: 'Shuddha Dhaivatam',
    centsFromSa: 800,
  ),
  SwarasthanaSpec(
    code: 'D2',
    shortLabel: 'D2',
    teluguScript: 'ద₂',
    fullName: 'Chatushruti Dhaivatam',
    centsFromSa: 900,
  ),
  SwarasthanaSpec(
    code: 'N2',
    shortLabel: 'N2',
    teluguScript: 'ని₂',
    fullName: 'Kaisiki Nishadam',
    centsFromSa: 1000,
  ),
  SwarasthanaSpec(
    code: 'N3',
    shortLabel: 'N',
    teluguScript: 'ని',
    fullName: 'Kakali Nishadam',
    centsFromSa: 1100,
  ),
  SwarasthanaSpec(
    code: 'S_high',
    shortLabel: 'Ṡ',
    teluguScript: 'స̇',
    fullName: 'Tara Shadjam',
    centsFromSa: 1200,
  ),
  SwarasthanaSpec(
    code: 'R_high',
    shortLabel: 'Ṙ',
    teluguScript: 'రి̇',
    fullName: 'Tara Shuddha Rishabham',
    centsFromSa: 1300,
  ),
  SwarasthanaSpec(
    code: 'G_high',
    shortLabel: 'Ġ',
    teluguScript: 'గ̇',
    fullName: 'Tara Antara Gandharam',
    centsFromSa: 1600,
  ),
];

SwarasthanaSpec resolveSwaraByToken(String rawToken) {
  final t = rawToken.trim();
  const Map<String, String> aliasMap = {
    'P̣': 'P_low',
    'Ṇ3': 'N3_low',
    'S': 'S',
    'R': 'R1',
    'R1': 'R1',
    'R2': 'R2',
    'G': 'G3',
    'G2': 'G2',
    'G3': 'G3',
    'M': 'M1',
    'M1': 'M1',
    'M2': 'M2',
    'P': 'P',
    'D': 'D1',
    'D1': 'D1',
    'D2': 'D2',
    'N': 'N3',
    'N2': 'N2',
    'N3': 'N3',
    'Ṡ': 'S_high',
    "S'": 'S_high',
    'Ṙ': 'R_high',
    "R'": 'R_high',
    'Ġ': 'G_high',
    "G'": 'G_high',
  };
  final code = aliasMap[t] ?? t;
  return kSwarasthanaTable.firstWhere(
    (s) => s.code == code,
    orElse: () => kSwarasthanaTable[2],
  );
}

class KaalamSpeed {
  final int kaalam;
  final String name;
  final String sanskritName;
  final int swarasPerBeat;

  const KaalamSpeed({
    required this.kaalam,
    required this.name,
    required this.sanskritName,
    required this.swarasPerBeat,
  });
}

const List<KaalamSpeed> kKaalamOptions = [
  KaalamSpeed(
    kaalam: 1,
    name: 'Tempo 1 (1st Kaalam)',
    sanskritName: 'Vilamba',
    swarasPerBeat: 1,
  ),
  KaalamSpeed(
    kaalam: 2,
    name: 'Tempo 2 (2nd Kaalam)',
    sanskritName: 'Madhya',
    swarasPerBeat: 2,
  ),
  KaalamSpeed(
    kaalam: 3,
    name: 'Tempo 3 (3rd Kaalam)',
    sanskritName: 'Druta',
    swarasPerBeat: 4,
  ),
  KaalamSpeed(
    kaalam: 4,
    name: 'Tempo 4 (4th Kaalam)',
    sanskritName: 'Ati-Druta',
    swarasPerBeat: 8,
  ),
];

class CarnaticLesson {
  final String id;
  final String group;
  final String title;
  final String raga;
  final String tala;
  final String description;
  final List<String> swaras;

  const CarnaticLesson({
    required this.id,
    required this.group,
    required this.title,
    required this.raga,
    required this.tala,
    required this.description,
    required this.swaras,
  });
}

const List<CarnaticLesson> kInitialLessons = [
  CarnaticLesson(
    id: 'sarali-1',
    group: 'Sarali Varisai',
    title: 'Sarali Varisai 1 — Arohanam & Avarohanam',
    raga: 'Mayamalavagowla (15th Melakarta)',
    tala: 'Adi Tala (8 Beats)',
    description: 'Foundation exercise ascending and descending through the 7 swarasthanas.',
    swaras: [
      'S',
      'R',
      'G',
      'M',
      'P',
      'D',
      'N',
      'Ṡ',
      'Ṡ',
      'N',
      'D',
      'P',
      'M',
      'G',
      'R',
      'S',
    ],
  ),
  CarnaticLesson(
    id: 'sarali-2',
    group: 'Sarali Varisai',
    title: 'Sarali Varisai 2 — Shadja-Rishabha Anchor',
    raga: 'Mayamalavagowla',
    tala: 'Adi Tala (8 Beats)',
    description: 'Anchors on S R S R S R G M before ascending to Tara Shadjam.',
    swaras: [
      'S',
      'R',
      'S',
      'R',
      'S',
      'R',
      'G',
      'M',
      'S',
      'R',
      'G',
      'M',
      'P',
      'D',
      'N',
      'Ṡ',
      'Ṡ',
      'N',
      'Ṡ',
      'N',
      'Ṡ',
      'N',
      'D',
      'P',
      'Ṡ',
      'N',
      'D',
      'P',
      'M',
      'G',
      'R',
      'S',
    ],
  ),
  CarnaticLesson(
    id: 'sarali-3',
    group: 'Sarali Varisai',
    title: 'Sarali Varisai 3 — Triplet Phrase Weave',
    raga: 'Mayamalavagowla',
    tala: 'Adi Tala (8 Beats)',
    description: 'Builds stability across S R G S R G S R phrases.',
    swaras: [
      'S',
      'R',
      'G',
      'S',
      'R',
      'G',
      'S',
      'R',
      'S',
      'R',
      'G',
      'M',
      'P',
      'D',
      'N',
      'Ṡ',
      'Ṡ',
      'N',
      'D',
      'Ṡ',
      'N',
      'D',
      'Ṡ',
      'N',
      'Ṡ',
      'N',
      'D',
      'P',
      'M',
      'G',
      'R',
      'S',
    ],
  ),
  CarnaticLesson(
    id: 'janta-1',
    group: 'Janta Varisai',
    title: 'Janta Varisai 1 — Double Swara Sphuritam',
    raga: 'Mayamalavagowla',
    tala: 'Adi Tala (8 Beats)',
    description:
        'Stresses pairs of identical swaras (SS RR GG MM) with gamaka impulse.',
    swaras: [
      'S',
      'S',
      'R',
      'R',
      'G',
      'G',
      'M',
      'M',
      'P',
      'P',
      'D',
      'D',
      'N',
      'N',
      'Ṡ',
      'Ṡ',
      'Ṡ',
      'Ṡ',
      'N',
      'N',
      'D',
      'D',
      'P',
      'P',
      'M',
      'M',
      'G',
      'G',
      'R',
      'R',
      'S',
      'S',
    ],
  ),
  CarnaticLesson(
    id: 'dhatu-1',
    group: 'Dhatu Varisai',
    title: 'Dhatu Varisai 1 — Zig-Zag Interval Leaps',
    raga: 'Mayamalavagowla',
    tala: 'Adi Tala (8 Beats)',
    description: 'Trains non-linear swara leaps (S M G M R G S R) for accurate vocal pitch.',
    swaras: [
      'S',
      'M',
      'G',
      'M',
      'R',
      'G',
      'S',
      'R',
      'S',
      'G',
      'R',
      'G',
      'S',
      'R',
      'G',
      'M',
      'S',
      'R',
      'G',
      'M',
      'P',
      'D',
      'N',
      'Ṡ',
      'Ṡ',
      'N',
      'D',
      'P',
      'M',
      'G',
      'R',
      'S',
    ],
  ),
  CarnaticLesson(
    id: 'geetham-1',
    group: 'Pillari Geetham',
    title: 'Sri Gananatha (Lambodara) — Malahari',
    raga: 'Malahari',
    tala: 'Rupaka / Adi Grid',
    description: 'Purandaradasa Pillari Geetham swara pallavi.',
    swaras: [
      'M',
      'P',
      'D',
      'Ṡ',
      'Ṡ',
      'Ṙ',
      'Ṙ',
      'Ṡ',
      'D',
      'P',
      'M',
      'P',
      'G',
      'R',
      'S',
      ',',
    ],
  ),
];

// ============================================================================
// 3. CUSTOM VECTOR ARTWORK WIDGETS (LOGO EMBLEM & MANDALA HERO BANNER)
// ============================================================================

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

/// Renders the widescreen SwaraGuru Hero Banner inspired by your attached banner:
/// Deep midnight indigo backdrop, ornate gold mandala corners, flowing cyan acoustic wave
/// with Telugu/Sanskrit swara script (స రి గ మ ప ద ని), gold serif title, and the Veena logo.
class SwaraGuruHeroBanner extends StatelessWidget {
  final ShrutiPitch activeShruti;
  final bool dronePlaying;
  final String droneSummary;
  final VoidCallback onToggleDrone;
  final VoidCallback onOpenShrutiDrawer;

  const SwaraGuruHeroBanner({
    super.key,
    required this.activeShruti,
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
                            'ADHARA SA: ${activeShruti.label} (${activeShruti.frequencyHz.toStringAsFixed(1)} Hz)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: SwaraColors.royalGold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
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

// ============================================================================
// 4. PITCH EVALUATION RESULT MODEL
// ============================================================================

enum NoteMatchStatus { match, apasruti, wrongSwara }

class StepPitchEvaluation {
  final int stepIndex;
  final String expectedSwara;
  final String sungSwara;
  final int centDeviation;
  final double sungFreqHz;
  final double expectedFreqHz;
  final NoteMatchStatus status;
  final String diagnosticMessage;

  const StepPitchEvaluation({
    required this.stepIndex,
    required this.expectedSwara,
    required this.sungSwara,
    required this.centDeviation,
    required this.sungFreqHz,
    required this.expectedFreqHz,
    required this.status,
    required this.diagnosticMessage,
  });
}

// ============================================================================
// 5. MAIN ADAPTIVE FLUTTER SCAFFOLD (DRAWERS, RAIL, BOTTOM BAR & POPUP MENUS)
// ============================================================================

enum ShrutiDroneMode { pureSingleNote, multiNoteChord }

enum _InfoPage { help, privacy, license }

extension on _InfoPage {
  String get title => switch (this) {
    _InfoPage.help => 'Help',
    _InfoPage.privacy => 'Privacy Policy',
    _InfoPage.license => 'License',
  };
}

class SwaraGuruAdaptiveScaffold extends StatefulWidget {
  const SwaraGuruAdaptiveScaffold({super.key, this.shrutiAudio});

  final ShrutiAudio? shrutiAudio;

  @override
  State<SwaraGuruAdaptiveScaffold> createState() =>
      _SwaraGuruAdaptiveScaffoldState();
}

class _SwaraGuruAdaptiveScaffoldState extends State<SwaraGuruAdaptiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation screen index: 0 = Varisai Studio, 1 = Live Pitch Coach, 2 = Shruti Drone Lab
  int _selectedScreenIndex = 0;
  _InfoPage? _infoPage;
  late Future<String> _readme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readme = DefaultAssetBundle.of(context).loadString('README.md');
  }

  static const _screenTitles = [
    'Varisai Studio',
    'Live Pitch Coach',
    'Shruti Drone Lab',
  ];

  String get _currentScreenTitle =>
      _infoPage?.title ?? _screenTitles[_selectedScreenIndex];

  void _selectScreen(int index) {
    setState(() {
      _selectedScreenIndex = index;
      _infoPage = null;
    });
  }

  // Base "Sa" (Adhara Shadjam) & Fine Tune
  ShrutiPitch _selectedShruti = kShrutiList[1]; // Default C# (1.5 Kattai)
  double _fineTuneCents = 0.0;

  // Kaalam (Tempo 1, 2, 3, 4) & BPM
  KaalamSpeed _selectedKaalam = kKaalamOptions[0];
  int _bpm = 68;

  // Repertoire & Custom Lessons
  final List<CarnaticLesson> _lessons = List.of(kInitialLessons);
  late CarnaticLesson _activeLesson;

  // Shruti Box State: Pure Single Note vs. Multi-Note Tambura
  bool _dronePlaying = false;
  bool _droneStarting = false;
  late final ShrutiAudio _shrutiAudio = widget.shrutiAudio ?? ShrutiAudio();
  ShrutiDroneMode _droneMode = ShrutiDroneMode.multiNoteChord;
  String _pureSwaraCode = 'S';
  final Map<String, double> _multiNoteMix = {
    'P_low': 0.45,
    'N3_low': 0.0,
    'S': 0.95,
    'M1': 0.0,
    'M2': 0.0,
    'P': 0.80,
    'N3': 0.0,
    'S_high': 0.70,
  };
  double _masterDroneVolume = 0.55;

  // Playback & Real-Time Pitch Coaching State
  Timer? _transportTimer;
  bool _isPlayingReference = false;
  bool _isPitchCoaching = false;
  bool _simulateStudentMistakes = true;
  int _activeStepIndex = -1;
  int _activeAdiTalaBeat = 1;

  // Live Pitch Readout & Step Evaluations
  String _detectedSwaraLabel = '—';
  String _detectedSwaraFullName = 'Ready to Listen';
  double _detectedFreqHz = 0.0;
  int _detectedCentError = 0;
  final Map<int, StepPitchEvaluation> _stepEvaluations = {};

  @override
  void initState() {
    super.initState();
    _activeLesson = _lessons.first;
  }

  @override
  void dispose() {
    _transportTimer?.cancel();
    unawaited(
      _shrutiAudio.dispose().catchError((Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'Shruti audio',
          ),
        );
      }),
    );
    super.dispose();
  }

  Map<double, double> get _droneVoices {
    if (_droneMode == ShrutiDroneMode.pureSingleNote) {
      return {_effectiveSaHz * resolveSwaraByToken(_pureSwaraCode).ratio: 1.0};
    }
    return {
      for (final entry in _multiNoteMix.entries)
        if (entry.value > 0)
          _effectiveSaHz * resolveSwaraByToken(entry.key).ratio: entry.value,
    };
  }

  Future<void> _toggleDrone() async {
    if (_droneStarting) return;
    try {
      if (_dronePlaying) {
        _shrutiAudio.stop();
        setState(() => _dronePlaying = false);
      } else {
        _droneStarting = true;
        await _shrutiAudio.start(_droneVoices, _masterDroneVolume);
        if (!mounted) {
          _shrutiAudio.stop();
          return;
        }
        _shrutiAudio.update(_droneVoices, _masterDroneVolume);
        setState(() => _dronePlaying = true);
      }
    } catch (error, stack) {
      _handleDroneError(error, stack);
    } finally {
      _droneStarting = false;
    }
  }

  void _updateDroneSettings(VoidCallback change) {
    setState(change);
    if (!_dronePlaying) return;
    try {
      _shrutiAudio.update(_droneVoices, _masterDroneVolume);
    } catch (error, stack) {
      _handleDroneError(error, stack);
    }
  }

  void _handleDroneError(Object error, StackTrace stack) {
    _shrutiAudio.stop();
    debugPrint('Shruti playback failed: $error\n$stack');
    if (!mounted) return;
    setState(() => _dronePlaying = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Unable to play Shruti: $error')));
  }

  double get _effectiveSaHz =>
      _selectedShruti.frequencyHz * math.pow(2.0, _fineTuneCents / 1200.0);

  String get _droneSummaryLabel {
    if (_droneMode == ShrutiDroneMode.pureSingleNote) {
      final spec = resolveSwaraByToken(_pureSwaraCode);
      return 'Pure ${spec.shortLabel}';
    }
    final active = _multiNoteMix.entries
        .where((e) => e.value > 0.05)
        .map((e) => resolveSwaraByToken(e.key).shortLabel)
        .toList();
    return active.isEmpty ? 'Muted' : 'Multi (${active.join(' + ')})';
  }

  // Starts or stops Varisai Playback or Vocal Pitch Coaching
  void _startTransport({required bool pitchCoaching}) {
    _stopTransport();

    setState(() {
      _isPlayingReference = !pitchCoaching;
      _isPitchCoaching = pitchCoaching;
      if (pitchCoaching) {
        _stepEvaluations.clear();
      }
    });

    final int swarasPerBeat = _selectedKaalam.swarasPerBeat;
    final int stepDurationMs = ((60.0 / _bpm / swarasPerBeat) * 1000).round();

    int cursor = 0;
    final List<String> sequence = _activeLesson.swaras;

    void tick() {
      if (!mounted) return;
      if (cursor >= sequence.length) {
        _stopTransport();
        return;
      }

      final String token = sequence[cursor];
      final SwarasthanaSpec expectedSpec = resolveSwaraByToken(token);
      final double expectedHz = _effectiveSaHz * expectedSpec.ratio;
      final int beat = ((cursor ~/ swarasPerBeat) % 8) + 1;

      setState(() {
        _activeStepIndex = cursor;
        _activeAdiTalaBeat = beat;

        if (!pitchCoaching) {
          _detectedSwaraLabel = expectedSpec.shortLabel;
          _detectedSwaraFullName = expectedSpec.fullName;
          _detectedFreqHz = expectedHz;
          _detectedCentError = 0;
        } else {
          // Evaluate vocal pitch against expected Swarasthana
          _evaluateStepVocalPitch(cursor, expectedSpec, expectedHz);
        }
      });

      HapticFeedback.selectionClick();
      cursor++;
    }

    tick();
    _transportTimer = Timer.periodic(
      Duration(milliseconds: stepDurationMs),
      (_) => tick(),
    );
  }

  void _stopTransport() {
    _transportTimer?.cancel();
    _transportTimer = null;
    if (mounted) {
      setState(() {
        _isPlayingReference = false;
        _isPitchCoaching = false;
        _activeStepIndex = -1;
      });
    }
  }

  void _evaluateStepVocalPitch(
    int stepIdx,
    SwarasthanaSpec expectedSpec,
    double expectedHz,
  ) {
    int simulatedCentOffset = 0;
    if (_simulateStudentMistakes) {
      if (expectedSpec.code == 'R1' && stepIdx % 5 == 1) {
        simulatedCentOffset = 104; // Student accidentally sang R2 instead of R1
      } else if (expectedSpec.code == 'G3' && stepIdx % 6 == 2) {
        simulatedCentOffset = -36; // Flat Gandharam (Apasruti)
      } else if (expectedSpec.code == 'D1' && stepIdx % 4 == 1) {
        simulatedCentOffset = 96; // Student sang D2 instead of D1
      } else {
        simulatedCentOffset = (math.Random().nextInt(18) - 9);
      }
    } else {
      simulatedCentOffset = (math.Random().nextInt(10) - 5);
    }

    final double sungHz =
        expectedHz * math.pow(2.0, simulatedCentOffset / 1200.0);
    final double totalCentsFromSa =
        1200.0 * (math.log(sungHz / _effectiveSaHz) / math.ln2);

    // Find closest Carnatic Swarasthana
    SwarasthanaSpec closest = kSwarasthanaTable[2];
    double minDiff = double.infinity;
    for (final s in kSwarasthanaTable) {
      final diff = (totalCentsFromSa - s.centsFromSa).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }

    final int centError = (totalCentsFromSa - closest.centsFromSa).round();
    NoteMatchStatus status = NoteMatchStatus.match;
    String message = 'Sruti Suddham (Exact Swarasthana)';

    if (closest.code != expectedSpec.code) {
      status = NoteMatchStatus.wrongSwara;
      message =
          'Sang ${closest.shortLabel} (${closest.fullName}) instead of ${expectedSpec.shortLabel}';
    } else if (centError.abs() > 25) {
      status = NoteMatchStatus.apasruti;
      message =
          'Apasruti: ${centError > 0 ? "+$centError" : "$centError"} cents drift on ${expectedSpec.shortLabel}';
    }

    _detectedSwaraLabel = closest.shortLabel;
    _detectedSwaraFullName = closest.fullName;
    _detectedFreqHz = sungHz;
    _detectedCentError = centError;

    _stepEvaluations[stepIdx] = StepPitchEvaluation(
      stepIndex: stepIdx,
      expectedSwara: expectedSpec.shortLabel,
      sungSwara: closest.shortLabel,
      centDeviation: centError,
      sungFreqHz: sungHz,
      expectedFreqHz: expectedHz,
      status: status,
      diagnosticMessage: message,
    );
  }

  void _openAddCustomSongDialog() {
    final titleCtrl = TextEditingController(text: 'Custom Varnam / Geetham');
    final ragaCtrl = TextEditingController(text: 'Mayamalavagowla');
    final notesCtrl = TextEditingController(
      text: 'S R G M P D N Ṡ Ṡ N D P M G R S',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SwaraColors.indigoSurface,
        title: const Text(
          'Add Custom Swara Sequence / Song',
          style: TextStyle(color: SwaraColors.brightGold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Song / Varisai Title',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ragaCtrl,
                decoration: const InputDecoration(labelText: 'Raga Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Swaras (space-separated: S R G M P D N Ṡ)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final tokens = notesCtrl.text
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (tokens.isNotEmpty) {
                final newLesson = CarnaticLesson(
                  id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                  group: 'Custom Song',
                  title: titleCtrl.text.trim(),
                  raga: ragaCtrl.text.trim(),
                  tala: 'Adi Tala (8 Beats)',
                  description: 'User-entered custom swara notation.',
                  swaras: tokens,
                );
                setState(() {
                  _lessons.add(newLesson);
                  _activeLesson = newLesson;
                  _stepEvaluations.clear();
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Load & Practice'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1024;
        final bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final bool isMobile = constraints.maxWidth < 600;

        return Scaffold(
          key: _scaffoldKey,
          appBar: _buildTopAppBar(isMobile),
          drawer: _buildLeftRepertoireAndScreenDrawer(),
          endDrawer: _buildRightShrutiEndDrawer(),
          body: Row(
            children: [
              if (isDesktop || isTablet)
                NavigationRail(
                  backgroundColor: SwaraColors.indigoSurface,
                  selectedIndex: _infoPage == null
                      ? _selectedScreenIndex
                      : null,
                  extended: isDesktop,
                  onDestinationSelected: _selectScreen,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SwaraGuruLogoEmblem(size: isDesktop ? 48 : 38),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Varisai Studio'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.mic_external_on_rounded),
                      label: Text('Live Pitch Coach'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.surround_sound_rounded),
                      label: Text('Shruti Drone Lab'),
                    ),
                  ],
                ),
              if (isDesktop || isTablet)
                const VerticalDivider(width: 1, color: SwaraColors.borderGold),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(
                    _infoPage?.name ?? 'screen-$_selectedScreenIndex',
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _infoPage == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwaraGuruHeroBanner(
                              activeShruti: _selectedShruti,
                              dronePlaying: _dronePlaying,
                              droneSummary: _droneSummaryLabel,
                              onToggleDrone: _toggleDrone,
                              onOpenShrutiDrawer: () =>
                                  _scaffoldKey.currentState?.openEndDrawer(),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedScreenIndex == 0)
                              _buildVarisaiStudioScreen(isDesktop),
                            if (_selectedScreenIndex == 1)
                              _buildPitchCoachScreen(),
                            if (_selectedScreenIndex == 2)
                              _buildShrutiDroneLabScreen(),
                          ],
                        )
                      : _buildInfoPage(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile && _infoPage == null
              ? NavigationBar(
                  backgroundColor: SwaraColors.indigoSurface,
                  selectedIndex: _selectedScreenIndex,
                  onDestinationSelected: _selectScreen,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: 'Studio',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.mic_external_on_rounded),
                      label: 'Pitch Coach',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.surround_sound_rounded),
                      label: 'Shruti Box',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  // ==========================================================================
  // TOP APP BAR WITH DRAWER TRIGGERS & POPUP MENU CHOICES
  // ==========================================================================

  PreferredSizeWidget _buildTopAppBar(bool isMobile) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Open Navigation & Varisai Drawer',
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          if (!isMobile) ...[
            const SwaraGuruLogoEmblem(size: 32),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SwaraGuru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: SwaraColors.brightGold,
                  ),
                ),
                Text(
                  _currentScreenTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Home (Varisai Studio)',
          onPressed: () => _selectScreen(0),
          icon: const Icon(Icons.home_rounded),
        ),
        // 1. PopupMenuButton for Base "Sa" (A, A#, B, B#, C, C#...)
        PopupMenuButton<ShrutiPitch>(
          tooltip: 'Select Base Sa (Adhara Shadjam)',
          initialValue: _selectedShruti,
          onSelected: (shruti) =>
              _updateDroneSettings(() => _selectedShruti = shruti),
          itemBuilder: (ctx) => kShrutiList
              .map(
                (s) => PopupMenuItem(
                  value: s,
                  child: Text(
                    'Sa = ${s.label} • ${s.kattaiName} (${s.frequencyHz.toStringAsFixed(1)} Hz)',
                  ),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SwaraColors.midnightBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SwaraColors.borderGold),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.music_note,
                  size: 15,
                  color: SwaraColors.royalGold,
                ),
                const SizedBox(width: 4),
                Text(
                  'Sa: ${_selectedShruti.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2. PopupMenuButton for Kaalam Tempo (1, 2, 3, 4)
        if (!isMobile)
          PopupMenuButton<KaalamSpeed>(
            tooltip: 'Select Kaalam Tempo (1, 2, 3, 4)',
            initialValue: _selectedKaalam,
            onSelected: (k) {
              _stopTransport();
              setState(() => _selectedKaalam = k);
            },
            itemBuilder: (ctx) => kKaalamOptions
                .map(
                  (k) => PopupMenuItem(
                    value: k,
                    child: Text('${k.name} (${k.swarasPerBeat} Swaras/Beat)'),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SwaraColors.midnightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SwaraColors.borderGold),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.speed,
                    size: 15,
                    color: SwaraColors.cyanWave,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tempo ${_selectedKaalam.kaalam} (${_selectedKaalam.swarasPerBeat}x)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),

        // 3. EndDrawer Trigger for Pure vs Multi-Note Shruti Box
        IconButton(
          tooltip: 'Open Shruti Box EndDrawer',
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: Icon(
            _dronePlaying ? Icons.volume_up_rounded : Icons.tune_rounded,
            color: _dronePlaying ? SwaraColors.royalGold : Colors.white70,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ==========================================================================
  // LEFT NAVIGATION DRAWER (SCREENS + SARALI/JANTA/DHATU VARISAI LIBRARY)
  // ==========================================================================

  Widget _buildLeftRepertoireAndScreenDrawer() {
    return Drawer(
      width: 320,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Branded Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: SwaraColors.borderGold),
                ),
              ),
              child: const Row(
                children: [
                  SwaraGuruLogoEmblem(size: 46),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SwaraGuru Studio',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SwaraColors.brightGold,
                          ),
                        ),
                        Text(
                          'Screens & Varisai Library',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Screen Navigation Choices
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'APP SCREENS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: SwaraColors.royalGold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('Varisai Studio (Adi Tala Grid)'),
              selected: _infoPage == null && _selectedScreenIndex == 0,
              onTap: () {
                _selectScreen(0);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_external_on_rounded),
              title: const Text('Live Vocal Pitch Coach'),
              selected: _infoPage == null && _selectedScreenIndex == 1,
              onTap: () {
                _selectScreen(1);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.surround_sound_rounded),
              title: const Text('Shruti Drone Lab (Pure / Multi)'),
              selected: _infoPage == null && _selectedScreenIndex == 2,
              onTap: () {
                _selectScreen(2);
                Navigator.of(context).pop();
              },
            ),
            const Divider(color: SwaraColors.borderGold),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'HELP & LEGAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: SwaraColors.royalGold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Help'),
              selected: _infoPage == _InfoPage.help,
              onTap: () => _openInfoPage(_InfoPage.help),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              selected: _infoPage == _InfoPage.privacy,
              onTap: () => _openInfoPage(_InfoPage.privacy),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('License'),
              selected: _infoPage == _InfoPage.license,
              onTap: () => _openInfoPage(_InfoPage.license),
            ),
            const Divider(color: SwaraColors.borderGold),

            // Carnatic Repertoire List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'REPERTOIRE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: SwaraColors.royalGold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openAddCustomSongDialog();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Custom', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            ..._lessons.map((lesson) {
              final selected = lesson.id == _activeLesson.id;
              return ListTile(
                selected: selected,
                selectedTileColor: SwaraColors.royalGold.withValues(
                  alpha: 0.15,
                ),
                title: Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${lesson.group} • ${lesson.swaras.length} Swaras',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
                onTap: () {
                  _stopTransport();
                  setState(() {
                    _activeLesson = lesson;
                    _stepEvaluations.clear();
                    _selectedScreenIndex = 0;
                    _infoPage = null;
                  });
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openInfoPage(_InfoPage page) {
    setState(() => _infoPage = page);
    Navigator.of(context).pop();
  }

  Widget _buildInfoPage() {
    final page = _infoPage!;
    final title = page.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: SwaraColors.brightGold,
          ),
        ),
        const SizedBox(height: 8),
        Text(switch (page) {
          _InfoPage.help => 'Guides and answers for using SwaraGuru.',
          _InfoPage.privacy => 'How SwaraGuru handles information and audio.',
          _InfoPage.license => 'The terms for using SwaraGuru source code.',
        }, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        switch (page) {
          _InfoPage.help => _buildHelpContent(),
          _InfoPage.privacy => _buildPrivacyContent(),
          _InfoPage.license => _buildLicenseContent(),
        },
      ],
    );
  }

  Widget _buildHelpContent() {
    return FutureBuilder<String>(
      future: _readme,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load the documentation: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Text('Loading documentation...');
        }
        return _infoCard('README (Markdown)', snapshot.data!);
      },
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      children: [
        _infoCard('Effective date', 'November 17, 2026'),
        _infoCard(
          'Information handled by the app',
          'SwaraGuru does not require an account and the app does not collect '
              'or transmit personal information, usage analytics, or '
              'microphone recordings. Custom lessons and practice selections '
              'are held in app memory for the current session and are not '
              'saved after you close it.',
        ),
        _infoCard(
          'Audio and microphone',
          'The Shruti Drone Lab generates tones locally in your browser when '
              'you start playback; it does not send audio to a server. The '
              'Live Pitch Coach is a simulation and does not request or use '
              'microphone access.',
        ),
        _infoCard(
          'Web hosting',
          'If you use the hosted web app, GitHub Pages may process standard '
              'connection information such as your IP address and browser '
              'request data to deliver the site. That processing is governed '
              'by GitHub’s privacy policy: https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement.',
        ),
        _infoCard(
          'Changes and contact',
          'If app behavior changes, this policy will be updated. Questions '
              'or privacy concerns can be raised at '
              'https://github.com/kvedala/swaraguru/issues. GitHub Issues '
              'are public, so do not post personal or sensitive information.',
        ),
      ],
    );
  }

  Widget _buildLicenseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          'MIT License',
          'Copyright (c) 2026 SwaraGuru contributors\n\n'
              'Permission is hereby granted, free of charge, to any person '
              'obtaining a copy of this software and associated documentation '
              'files (the "Software"), to deal in the Software without '
              'restriction, including without limitation the rights to use, '
              'copy, modify, merge, publish, distribute, sublicense, and/or '
              'sell copies of the Software, and to permit persons to whom the '
              'Software is furnished to do so, subject to the following '
              'conditions:\n\n'
              'The above copyright notice and this permission notice shall be '
              'included in all copies or substantial portions of the '
              'Software.\n\n'
              'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY '
              'KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE '
              'WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR '
              'PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR '
              'COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
              'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, '
              'ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE '
              'USE OR OTHER DEALINGS IN THE SOFTWARE.',
        ),
        _infoCard(
          'Third-party components',
          'This license applies to SwaraGuru project source code. Third-party '
              'packages and components remain subject to their own licenses.',
        ),
      ],
    );
  }

  Widget _infoCard(String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: SwaraColors.royalGold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: const TextStyle(height: 1.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // RIGHT END DRAWER (PURE SINGLE NOTE vs. MULTI-NOTE SHRUTI BOX MIXER)
  // ==========================================================================

  Widget _buildRightShrutiEndDrawer() {
    return Drawer(
      width: 360,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shruti Drone Mixer',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SwaraColors.brightGold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Choose between a Pure Single Note reference or a Multi-Note Tambura chord.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildShrutiConfigurationControls(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShrutiConfigurationControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented Mode Toggle: Pure Single Note vs. Multi-Note Chord
        SegmentedButton<ShrutiDroneMode>(
          segments: const [
            ButtonSegment(
              value: ShrutiDroneMode.pureSingleNote,
              icon: Icon(Icons.looks_one_rounded),
              label: Text('Pure Single Note'),
            ),
            ButtonSegment(
              value: ShrutiDroneMode.multiNoteChord,
              icon: Icon(Icons.graphic_eq_rounded),
              label: Text('Multiple Notes'),
            ),
          ],
          selected: {_droneMode},
          onSelectionChanged: (selection) {
            _updateDroneSettings(() => _droneMode = selection.first);
          },
        ),
        const SizedBox(height: 16),

        if (_droneMode == ShrutiDroneMode.pureSingleNote) ...[
          const Text(
            'Select Isolated Pure Reference Swara:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: SwaraColors.royalGold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['S', 'M1', 'M2', 'P', 'N3', 'S_high'].map((code) {
              final spec = resolveSwaraByToken(code);
              final hz = _effectiveSaHz * spec.ratio;
              final isSelected = _pureSwaraCode == code;
              return ChoiceChip(
                label: Text('${spec.shortLabel} (${hz.round()} Hz)'),
                selected: isSelected,
                onSelected: (_) =>
                    _updateDroneSettings(() => _pureSwaraCode = code),
              );
            }).toList(),
          ),
        ] else ...[
          const Text(
            'Multi-Note Tambura Channels (Toggle & Mix):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: SwaraColors.royalGold,
            ),
          ),
          const SizedBox(height: 8),
          ..._multiNoteMix.keys.map((code) {
            final spec = resolveSwaraByToken(code);
            final vol = _multiNoteMix[code] ?? 0.0;
            final hz = _effectiveSaHz * spec.ratio;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SwaraColors.midnightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: vol > 0.05 ? SwaraColors.royalGold : Colors.white12,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${spec.shortLabel} • ${spec.fullName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${hz.toStringAsFixed(1)} Hz (${(vol * 100).round()}%)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: SwaraColors.cyanWave,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: vol,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) =>
                          _updateDroneSettings(() => _multiNoteMix[code] = v),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        const Text(
          'Master Shruti Volume & Fine Tuning (Cents)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: SwaraColors.royalGold,
          ),
        ),
        Slider(
          value: _masterDroneVolume,
          min: 0.05,
          max: 1.0,
          label: 'Volume ${(100 * _masterDroneVolume).round()}%',
          onChanged: (v) => _updateDroneSettings(() => _masterDroneVolume = v),
        ),
        Slider(
          value: _fineTuneCents,
          min: -50,
          max: 50,
          label: '${_fineTuneCents.round()} cents',
          onChanged: (v) => _updateDroneSettings(() => _fineTuneCents = v),
        ),
      ],
    );
  }

  // ==========================================================================
  // SCREEN 1: VARISAI STUDIO (BASE SA, KAALAM 1-4, ADI TALA SWARA GRID)
  // ==========================================================================

  Widget _buildVarisaiStudioScreen(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Base "Sa" Chip Selector Strip + Kaalam 1, 2, 3, 4 Selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT BASE "SA" (A, A#, B, B#, C, C# ... G#) & TEMPO (KAALAM 1–4)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: SwaraColors.royalGold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kShrutiList.map((shruti) {
                    final bool isSelected = shruti.id == _selectedShruti.id;
                    return ChoiceChip(
                      label: Text(
                        '${shruti.label} (${shruti.frequencyHz.round()}Hz)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? SwaraColors.midnightBg
                              : Colors.white,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: SwaraColors.royalGold,
                      backgroundColor: SwaraColors.midnightBg,
                      onSelected: (_) =>
                          _updateDroneSettings(() => _selectedShruti = shruti),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...kKaalamOptions.map((k) {
                      final bool active = k.kaalam == _selectedKaalam.kaalam;
                      return ChoiceChip(
                        label: Text(
                          'Tempo ${k.kaalam} • ${k.sanskritName} (${k.swarasPerBeat}x)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: active
                                ? SwaraColors.midnightBg
                                : SwaraColors.cyanWave,
                          ),
                        ),
                        selected: active,
                        selectedColor: SwaraColors.cyanWave,
                        backgroundColor: SwaraColors.midnightBg,
                        onSelected: (_) {
                          _stopTransport();
                          setState(() => _selectedKaalam = k);
                        },
                      );
                    }),
                    const SizedBox(width: 12),
                    Text(
                      'Laya BPM: $_bpm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SwaraColors.brightGold,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Slider(
                        value: _bpm.toDouble(),
                        min: 40,
                        max: 140,
                        divisions: 100,
                        onChanged: (v) => setState(() => _bpm = v.round()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Adi Tala 8-Beat Swara Grid Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeLesson.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: SwaraColors.brightGold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Raga: ${_activeLesson.raga} • ${_activeLesson.tala} • ${_selectedKaalam.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!_isPlayingReference && !_isPitchCoaching) ...[
                          FilledButton.icon(
                            onPressed: () =>
                                _startTransport(pitchCoaching: false),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: const Text('Play Varisai'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _startTransport(pitchCoaching: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: SwaraColors.crimsonRobes,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.mic_rounded, size: 18),
                            label: const Text('Sing & Match Swaras'),
                          ),
                        ] else
                          FilledButton.icon(
                            onPressed: _stopTransport,
                            style: FilledButton.styleFrom(
                              backgroundColor: SwaraColors.crimsonRobes,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 18),
                            label: const Text('Stop Transport'),
                          ),
                        OutlinedButton.icon(
                          onPressed: _openAddCustomSongDialog,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Custom Song'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Adi Tala 8-Beat Indicator Strip (Laghu 4 + Dhrutam 2 + Dhrutam 2)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(8, (i) {
                    final int beatNum = i + 1;
                    final bool isCurrentBeat =
                        (_isPlayingReference || _isPitchCoaching) &&
                        _activeAdiTalaBeat == beatNum;
                    final String kriya = beatNum == 1
                        ? 'Clap (Laghu)'
                        : beatNum <= 4
                        ? 'Finger ${beatNum - 1}'
                        : (beatNum.isOdd ? 'Clap (Dhrutam)' : 'Wave');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentBeat
                            ? SwaraColors.royalGold
                            : SwaraColors.midnightBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentBeat
                              ? SwaraColors.brightGold
                              : SwaraColors.borderGold,
                        ),
                      ),
                      child: Text(
                        'Beat $beatNum • $kriya',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCurrentBeat
                              ? SwaraColors.midnightBg
                              : Colors.white70,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Interactive Swara Notation Cells
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_activeLesson.swaras.length, (idx) {
                    final String token = _activeLesson.swaras[idx];
                    final SwarasthanaSpec spec = resolveSwaraByToken(token);
                    final double expectedHz = _effectiveSaHz * spec.ratio;
                    final bool isActiveStep = _activeStepIndex == idx;
                    final StepPitchEvaluation? eval = _stepEvaluations[idx];

                    Color borderColor = SwaraColors.borderGold;
                    Color cellBg = SwaraColors.midnightBg;

                    if (isActiveStep) {
                      borderColor = SwaraColors.brightGold;
                      cellBg = SwaraColors.royalGold.withValues(alpha: 0.25);
                    } else if (eval != null) {
                      if (eval.status == NoteMatchStatus.match) {
                        borderColor = SwaraColors.emeraldMatch;
                        cellBg = SwaraColors.emeraldMatch.withValues(
                          alpha: 0.16,
                        );
                      } else if (eval.status == NoteMatchStatus.apasruti) {
                        borderColor = SwaraColors.warmAmber;
                        cellBg = SwaraColors.warmAmber.withValues(alpha: 0.18);
                      } else {
                        borderColor = SwaraColors.crimsonRobes;
                        cellBg = SwaraColors.crimsonRobes.withValues(
                          alpha: 0.22,
                        );
                      }
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _activeStepIndex = idx;
                          _detectedSwaraLabel = spec.shortLabel;
                          _detectedSwaraFullName = spec.fullName;
                          _detectedFreqHz = expectedHz;
                          _detectedCentError = 0;
                        });
                      },
                      child: Container(
                        width: 78,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cellBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: isActiveStep ? 2.0 : 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              token,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              spec.teluguScript,
                              style: const TextStyle(
                                fontSize: 11,
                                color: SwaraColors.royalGold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              eval != null
                                  ? (eval.status == NoteMatchStatus.wrongSwara
                                        ? 'Sang ${eval.sungSwara}'
                                        : '${eval.centDeviation >= 0 ? "+${eval.centDeviation}" : eval.centDeviation}c')
                                  : '${expectedHz.round()} Hz',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    eval != null &&
                                        eval.status ==
                                            NoteMatchStatus.wrongSwara
                                    ? const Color(0xFFFDA4AF)
                                    : SwaraColors.cyanWave,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Vocal Pitch & Mistake Summary Footer Card
        _buildPitchCoachSummaryBanner(),
      ],
    );
  }

  Widget _buildPitchCoachSummaryBanner() {
    final total = _stepEvaluations.length;
    final matched = _stepEvaluations.values
        .where((e) => e.status == NoteMatchStatus.match)
        .length;
    final apasruti = _stepEvaluations.values
        .where((e) => e.status == NoteMatchStatus.apasruti)
        .length;
    final wrong = _stepEvaluations.values
        .where((e) => e.status == NoteMatchStatus.wrongSwara)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SwaraColors.midnightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SwaraColors.royalGold),
                  ),
                  child: Text(
                    _detectedSwaraLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: SwaraColors.brightGold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _detectedSwaraFullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _detectedFreqHz > 0
                            ? '${_detectedFreqHz.toStringAsFixed(1)} Hz (${_detectedCentError >= 0 ? "+$_detectedCentError" : _detectedCentError} cents from Swarasthana)'
                            : 'Tap any Swara cell or press "Sing & Match Swaras"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: SwaraColors.cyanWave,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (total > 0)
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    backgroundColor: SwaraColors.emeraldMatch.withValues(
                      alpha: 0.2,
                    ),
                    label: Text('Matched: $matched/$total'),
                  ),
                  Chip(
                    backgroundColor: SwaraColors.warmAmber.withValues(
                      alpha: 0.2,
                    ),
                    label: Text('Apasruti: $apasruti'),
                  ),
                  Chip(
                    backgroundColor: SwaraColors.crimsonRobes.withValues(
                      alpha: 0.2,
                    ),
                    label: Text('Wrong Swara: $wrong'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SCREEN 2: LIVE VOCAL PITCH COACH & SWARASTHANA MISTAKE DIAGNOSTICS
  // ==========================================================================

  Widget _buildPitchCoachScreen() {
    final mistakes = _stepEvaluations.values
        .where((e) => e.status != NoteMatchStatus.match)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Real-Time Vocal Pitch Analyzer & Mistake Coach',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: SwaraColors.brightGold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Listens to your singing relative to Adhara Sa and flags Apasruti drift or wrong Swarasthanas.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        if (_isPitchCoaching) {
                          _stopTransport();
                        } else {
                          _startTransport(pitchCoaching: true);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _isPitchCoaching
                            ? SwaraColors.crimsonRobes
                            : SwaraColors.emeraldMatch,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(_isPitchCoaching ? Icons.stop : Icons.mic),
                      label: Text(
                        _isPitchCoaching
                            ? 'Stop Coaching'
                            : 'Start Sing & Match',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Simulate Realistic Student Mistakes (R2 instead of R1, Flat G3)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Toggle OFF to simulate a pitch-perfect Vidwan vocal performance.',
                    style: TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                  value: _simulateStudentMistakes,
                  onChanged: (v) =>
                      setState(() => _simulateStudentMistakes = v),
                ),
                const Divider(color: SwaraColors.borderGold),
                _buildPitchCoachSummaryBanner(),
                const SizedBox(height: 14),
                const Text(
                  'IDENTIFIED SWARASTHANA & APASRUTI MISTAKES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: SwaraColors.royalGold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                if (mistakes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No mistakes logged yet. Press "Start Sing & Match" to evaluate your singing against the active Varisai.',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  )
                else
                  ...mistakes.map(
                    (m) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      leading: Icon(
                        m.status == NoteMatchStatus.wrongSwara
                            ? Icons.cancel_rounded
                            : Icons.warning_amber_rounded,
                        color: m.status == NoteMatchStatus.wrongSwara
                            ? SwaraColors.crimsonRobes
                            : SwaraColors.warmAmber,
                      ),
                      title: Text(
                        'Step #${m.stepIndex + 1}: Expected ${m.expectedSwara} (${m.expectedFreqHz.toStringAsFixed(1)} Hz) • Sung ${m.sungSwara} (${m.sungFreqHz.toStringAsFixed(1)} Hz)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        m.diagnosticMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SCREEN 3: STANDALONE SHRUTI DRONE LAB (PURE SINGLE NOTE vs. MULTI-NOTE)
  // ==========================================================================

  Widget _buildShrutiDroneLabScreen() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shruti Box & Tambura Drone Synthesizer Lab',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SwaraColors.brightGold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select a Pure Single-Note reference or mix Multiple Tambura Swaras simultaneously.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _toggleDrone,
                  icon: Icon(_dronePlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_dronePlaying ? 'Stop Drone' : 'Start Drone'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildShrutiConfigurationControls(),
          ],
        ),
      ),
    );
  }
}
