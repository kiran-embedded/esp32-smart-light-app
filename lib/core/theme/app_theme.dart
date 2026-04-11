import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../../core/ui/adaptive_text_engine.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  darkNeon,
  softDark,
  cyberNeon,
  raindrop,
  amoledCyberpunk,
  darkSpace,
  // New Themes
  kaliLinux,
  nothingDot,
  crimsonVampire,
  neonTokyo,
  // v1.2 Expansion
  sunsetRetro,
  mindfulNature,
  deepOcean,
  dracula,
  monokai,
  synthwave,
  solarFlare,
  electricTundra,
  nanoCatalyst,
  phantomVelvet,
  prismFractal,
  magmaCore,
  cyberBloom,
  starlightEcho,
  // v1.3 Premium Edition
  pureGold,
  platinumBlue,
}

class AppTheme {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.darkNeon:
        return _darkNeonTheme;
      case AppThemeMode.softDark:
        return _softDarkTheme;
      case AppThemeMode.cyberNeon:
        return _cyberNeonTheme;
      case AppThemeMode.raindrop:
        return _raindropTheme;
      case AppThemeMode.amoledCyberpunk:
        return _amoledCyberpunkTheme;
      case AppThemeMode.darkSpace:
        return _darkSpaceTheme;
      case AppThemeMode.kaliLinux:
        return _kaliLinuxTheme;
      case AppThemeMode.nothingDot:
        return _nothingTheme;
      case AppThemeMode.crimsonVampire:
        return _crimsonTheme;
      case AppThemeMode.neonTokyo:
        return _neonTokyoTheme;
      case AppThemeMode.sunsetRetro:
        return _sunsetRetroTheme;
      case AppThemeMode.mindfulNature:
        return _mindfulNatureTheme;
      case AppThemeMode.deepOcean:
        return _deepOceanTheme;
      case AppThemeMode.dracula:
        return _draculaTheme;
      case AppThemeMode.monokai:
        return _monokaiTheme;
      case AppThemeMode.synthwave:
        return _synthwaveTheme;
      case AppThemeMode.solarFlare:
        return _solarFlareTheme;
      case AppThemeMode.electricTundra:
        return _electricTundraTheme;
      case AppThemeMode.nanoCatalyst:
        return _nanoCatalystTheme;
      case AppThemeMode.phantomVelvet:
        return _phantomVelvetTheme;
      case AppThemeMode.prismFractal:
        return _prismFractalTheme;
      case AppThemeMode.magmaCore:
        return _magmaCoreTheme;
      case AppThemeMode.cyberBloom:
        return _cyberBloomTheme;
      case AppThemeMode.starlightEcho:
        return _starlightEchoTheme;
      case AppThemeMode.pureGold:
        return _pureGoldTheme;
      case AppThemeMode.platinumBlue:
        return _platinumBlueTheme;
    }
  }

  static ThemeData get _darkNeonTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: const ColorScheme.dark(
        primary: Color(AppConstants.neonCyan),
        secondary: Color(AppConstants.neonBlue),
        surface: Color(0xFF1A1A1A),
        error: Color(0xFFFF4444),
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFFFFFFFF),
        onError: Color(0xFFFFFFFF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A).withOpacity(0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: _baseTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _softDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF64B5F6),
        secondary: Color(0xFF81C784),
        surface: Color(0xFF1E1E1E),
        error: Color(0xFFE57373),
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E).withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: _baseTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _pureGoldTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A05),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD700),
        secondary: Color(0xFFFFA000),
        surface: Color(0xFF1A1A10),
        onPrimary: Colors.black,
        onSurface: Color(0xFFFFE082),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A10).withOpacity(0.9),
        elevation: 8,
        shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 0.5),
        ),
      ),
      textTheme: GoogleFonts.getTextTheme('Outfit', _baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _platinumBlueTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF05050A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE5E4E2),
        secondary: Color(0xFF00B0FF),
        surface: Color(0xFF10101A),
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF101010).withOpacity(0.85),
        elevation: 10,
        shadowColor: const Color(0xFF00B0FF).withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE5E4E2), width: 0.3),
        ),
      ),
      textTheme: GoogleFonts.getTextTheme('Outfit', _baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _cyberNeonTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050510),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF9D),
        secondary: Color(0xFFBC13FE),
        surface: Color(0xFF0F0F25),
        onSurface: Color(0xFFE0E0FF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0F0F25).withOpacity(0.85),
        elevation: 5,
        shadowColor: const Color(0xFF00FF9D).withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: _baseTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _raindropTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF58A6FF),
        secondary: Color(0xFF79C0FF),
        surface: Color(0xFF161B22),
        onSurface: Color(0xFFC9D1D9),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22).withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF30363D), width: 1),
        ),
      ),
      textTheme: _baseTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _amoledCyberpunkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF0055),
        secondary: Color(0xFFE9FF00),
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111111),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      textTheme: _baseTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _darkSpaceTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF00),
        secondary: Color(0xFF00FF00),
        tertiary: Color(0xFF00FF00),
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
        error: Color(0xFFCF6679),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF121212).withOpacity(0.95),
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1E1E1E).withOpacity(0.9),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF).withOpacity(0.25),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      textTheme: _baseTextTheme.copyWith(
        displayLarge: _baseTextTheme.displayLarge?.copyWith(
          fontFamily: 'Outfit',
          letterSpacing: 1.2,
        ),
        bodyLarge: _baseTextTheme.bodyLarge?.copyWith(fontFamily: 'Roboto'),
      ),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _kaliLinuxTheme {
    const primary = Color(0xFF00FF00);
    const bg = Color(0xFF000000);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: const Color(0xFF1B1B1B),
        surface: const Color(0xFF0D0D0D),
        onPrimary: AdaptiveTextEngine.compute(primary),
        onSurface: const Color(0xFF00FF00),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0D0D0D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: primary.withOpacity(0.5)),
        ),
      ),
      textTheme: GoogleFonts.robotoMonoTextTheme(
        _baseTextTheme,
      ).apply(bodyColor: primary, displayColor: primary),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _nothingTheme {
    const primary = Color(0xFFD71921);
    const bg = Color(0xFF000000);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: Colors.white,
        surface: const Color(0xFF101010),
        onPrimary: AdaptiveTextEngine.compute(primary),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF101010),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
      ),
      textTheme: GoogleFonts.dotGothic16TextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _crimsonTheme {
    const primary = Color(0xFFDC143C);
    const secondary = Color(0xFFFFD700);
    const bg = Color(0xFF050000);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF1A0505),
        onPrimary: AdaptiveTextEngine.compute(primary),
        onSurface: const Color(0xFFFFE5E5),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A0505),
        elevation: 10,
        shadowColor: primary.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primary.withOpacity(0.3)),
        ),
      ),
      textTheme: GoogleFonts.cinzelTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _neonTokyoTheme {
    const primary = Color(0xFF00FFFF);
    const secondary = Color(0xFFFF00FF);
    const bg = Color(0xFF0b0014);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF180227),
        onPrimary: AdaptiveTextEngine.compute(primary),
        onSurface: const Color(0xFFFFD1FF),
        tertiary: const Color(0xFFFFFF00),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF180227).withOpacity(0.8),
        elevation: 8,
        shadowColor: secondary.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: secondary.withOpacity(0.6), width: 1.5),
        ),
      ),
      textTheme: GoogleFonts.orbitronTextTheme(_baseTextTheme).apply(
        bodyColor: const Color(0xFFFFD1FF),
        displayColor: const Color(0xFF00FFFF),
      ),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _sunsetRetroTheme {
    const primary = Color(0xFFFF9E80);
    const secondary = Color(0xFFEA80FC);
    const bg = Color(0xFF2D1B2E);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF4A2C46),
        onPrimary: const Color(0xFF560027),
        onSurface: const Color(0xFFFFE0B2),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF4A2C46).withOpacity(0.9),
        elevation: 8,
        shadowColor: primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: GoogleFonts.comfortaaTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _mindfulNatureTheme {
    const primary = Color(0xFF66BB6A);
    const secondary = Color(0xFF8D6E63);
    const bg = Color(0xFF1B261D);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF253326),
        onPrimary: Colors.white,
        onSurface: const Color(0xFFE8F5E9),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF253326).withOpacity(0.8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: primary.withOpacity(0.2)),
        ),
      ),
      textTheme: GoogleFonts.quicksandTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _deepOceanTheme {
    const primary = Color(0xFF00BFA5);
    const secondary = Color(0xFF40C4FF);
    const bg = Color(0xFF001018);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF002029),
        onSurface: const Color(0xFFE0F7FA),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF002029).withOpacity(0.85),
        elevation: 12,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: secondary.withOpacity(0.1)),
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _draculaTheme {
    const bg = Color(0xFF282A36);
    const primary = Color(0xFFBD93F9);
    const secondary = Color(0xFFFF79C6);
    const surface = Color(0xFF44475A);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: bg,
        onSurface: const Color(0xFFF8F8F2),
        error: const Color(0xFFFF5555),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: GoogleFonts.firaCodeTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _monokaiTheme {
    const bg = Color(0xFF2D2A2E);
    const primary = Color(0xFFFC9867);
    const secondary = Color(0xFFFFD866);
    const surface = Color(0xFF403E41);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: const Color(0xFFFF6188),
        surface: surface,
        onSurface: const Color(0xFFFCFCFA),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _synthwaveTheme {
    const bg = Color(0xFF241734);
    const primary = Color(0xFFEB00FF);
    const secondary = Color(0xFF00F0FF);
    const surface = Color(0xFF2E2142);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: const Color(0xFFF0E6FF),
      ),
      cardTheme: CardThemeData(
        color: surface.withOpacity(0.9),
        elevation: 10,
        shadowColor: primary.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide(color: secondary.withOpacity(0.7), width: 1.5),
        ),
      ),
      textTheme: GoogleFonts.pressStart2pTextTheme(
        _baseTextTheme,
      ).apply(bodyColor: Colors.white, displayColor: secondary),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _solarFlareTheme {
    const primary = Color(0xFFFF5722);
    const secondary = Color(0xFFFFC107);
    const bg = Color(0xFF1A0A00);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF2D1400),
        onPrimary: Colors.white,
        onSurface: const Color(0xFFFFE0B2),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D1400).withOpacity(0.9),
        elevation: 12,
        shadowColor: primary.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      textTheme: GoogleFonts.getTextTheme('Outfit', _baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _electricTundraTheme {
    const primary = Color(0xFF00E5FF);
    const secondary = Color(0xFF2979FF);
    const bg = Color(0xFF001219);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF001B24),
        onPrimary: Colors.black,
        onSurface: const Color(0xFFE0F7FA),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF001B24).withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primary.withOpacity(0.3)),
        ),
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _nanoCatalystTheme {
    const primary = Color(0xFFE0E0E0);
    const secondary = Color(0xFF00FF9D);
    const bg = Color(0xFF0A0A0A);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF141414),
        onPrimary: Colors.black,
        onSurface: Colors.white70,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141414),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: primary.withOpacity(0.2)),
        ),
      ),
      textTheme: GoogleFonts.shareTechMonoTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _phantomVelvetTheme {
    const primary = Color(0xFF9C27B0);
    const secondary = Color(0xFFE91E63);
    const bg = Color(0xFF0D0014);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF1A0027),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A0027).withOpacity(0.9),
        elevation: 20,
        shadowColor: primary.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: GoogleFonts.quicksandTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _prismFractalTheme {
    const primary = Colors.white;
    const secondary = Color(0xFF757575);
    const bg = Color(0xFF050505);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF111111),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111111),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
      textTheme: GoogleFonts.mavenProTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _magmaCoreTheme {
    const primary = Color(0xFFFF3D00);
    const secondary = Color(0xFFD50000);
    const bg = Color(0xFF0E0000);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF1F0000),
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F0000).withOpacity(0.95),
        elevation: 15,
        shadowColor: primary.withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: GoogleFonts.kanitTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _cyberBloomTheme {
    const primary = Color(0xFF00FF88);
    const secondary = Color(0xFF88FF00);
    const bg = Color(0xFF050F08);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF0A1F12),
        onSurface: Colors.white70,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0A1F12).withOpacity(0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
          side: BorderSide(color: primary.withOpacity(0.3)),
        ),
      ),
      textTheme: GoogleFonts.firaSansTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _starlightEchoTheme {
    const primary = Color(0xFFB0BEC5);
    const secondary = Colors.white;
    const bg = Color(0xFF070A0F);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF0E141B),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0E141B).withOpacity(0.9),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.montserratTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static const AppBarTheme _baseAppBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  static const TextTheme _baseTextTheme = TextTheme(
    displayLarge: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
    bodyMedium: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
    bodySmall: TextStyle(color: Color(0xFF999999), fontSize: 12),
  );

  static double getThemeGlowIntensity(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.darkNeon:
      case AppThemeMode.cyberNeon:
      case AppThemeMode.neonTokyo:
      case AppThemeMode.synthwave:
      case AppThemeMode.solarFlare:
      case AppThemeMode.magmaCore:
      case AppThemeMode.cyberBloom:
      case AppThemeMode.pureGold:
      case AppThemeMode.platinumBlue:
        return 1.5;
      case AppThemeMode.amoledCyberpunk:
      case AppThemeMode.darkSpace:
      case AppThemeMode.phantomVelvet:
      case AppThemeMode.crimsonVampire:
        return 1.0;
      case AppThemeMode.raindrop:
      case AppThemeMode.deepOcean:
      case AppThemeMode.starlightEcho:
      case AppThemeMode.electricTundra:
        return 0.7;
      case AppThemeMode.softDark:
      case AppThemeMode.kaliLinux:
      case AppThemeMode.nothingDot:
      case AppThemeMode.nanoCatalyst:
      case AppThemeMode.prismFractal:
        return 0.4;
      default:
        return 0.5;
    }
  }
}

class GlassmorphicDecoration {
  static BoxDecoration getDecoration({
    required Color baseColor,
    double opacity = 0.15,
    double blur = 45.0,
    double borderRadius = 28,
    Color? borderColor,
    double borderWidth = 0.8,
  }) {
    return BoxDecoration(
      color: baseColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.15),
        width: borderWidth,
      ),
      boxShadow: const [],
    );
  }
}
