import 'package:material_ui/material_ui.dart';

/// Brand colour tokens taken from the SwaraGuru logo and banner artwork.
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

ThemeData buildSwaraTheme() => ThemeData(
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
);
