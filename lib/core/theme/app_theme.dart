import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../../core/ui/adaptive_text_engine.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  darkNeon,
  softDark,
  light,
  cyberNeon,
  liquidGlass,
  raindrop,
  amoledCyberpunk,
  darkSpace,
  // New Themes
  kaliLinux,
  nothingDot,
  appleGlass,
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
  voidRift,
  starlightEcho,
  aeroStream,
}

class AppTheme {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.darkNeon:
        return _darkNeonTheme;
      case AppThemeMode.softDark:
        return _softDarkTheme;
      case AppThemeMode.light:
        return _lightTheme;
      case AppThemeMode.cyberNeon:
        return _cyberNeonTheme;
      case AppThemeMode.liquidGlass:
        return _liquidGlassTheme;
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
      case AppThemeMode.appleGlass:
        return _appleGlassTheme;
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
      case AppThemeMode.voidRift:
        return _voidRiftTheme;
      case AppThemeMode.starlightEcho:
        return _starlightEchoTheme;
      case AppThemeMode.aeroStream:
        return _aeroStreamTheme;
    }
  }

  // ... (Existing themes _darkNeonTheme, _softDarkTheme, _lightTheme remain if you want to keep them,
  // but I will output the FULL file content or just the new methods to append if I was appending,
  // but here I will just add the new ones and keep the old ones via the tool logic if I can,
  // however replace_file_content replaces a block. I should probably just replace the whole class or add carefully.)
  // Actually, I'll replace the class content to ensure all are present.

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
      // Reduced transparency from 0.6 to 0.8 for better visibility
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
        color: const Color(0xFF1E1E1E).withOpacity(0.9), // Less transparent
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: _baseTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: Color(0xFF388E3C),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFD32F2F),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: _lightTextTheme, // need to define or inline
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }

  // --- NEW THEMES ---

  static ThemeData get _cyberNeonTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050510), // Deep blue-black
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF9D), // Spring Green Neon
        secondary: Color(0xFFBC13FE), // Electric Purple
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

  static ThemeData get _liquidGlassTheme {
    // iPhone 26 like - Ultra clean, white/silver, high blur feel (simulated via colors)
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE0E5EC), // Neumorphic grey-ish
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2979FF), // Vivid Blue
        secondary: Color(0xFF00E5FF),
        surface: Color(0xFFF0F5FA),
        onSurface: Color(0xFF2D3142),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF).withOpacity(0.6), // Glassy but visible
        elevation: 0, // No shadow for glass
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
      ),
      textTheme: _lightTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _raindropTheme {
    // Moody, dark blue/purple, like rain on a window
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(
        0xFF0D1117,
      ), // GitHub Dark Dimmed style
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF58A6FF), // Soft Blue
        secondary: Color(0xFF79C0FF),
        surface: Color(0xFF161B22),
        onSurface: Color(0xFFC9D1D9),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22).withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFF30363D), width: 1),
        ),
      ),
      textTheme: _baseTextTheme,
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _amoledCyberpunkTheme {
    // True Black, High Contrast
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000), // True Amoled Black
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF0055), // Neon Pink
        secondary: Color(0xFFE9FF00), // Neon Yellow
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111111), // Almost black for contrast cards
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0), // Sharp edges for cyberpunk
          side: BorderSide(color: Color(0xFF333333), width: 1),
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
      scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF00), // Toxic Green
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
        color: const Color(
          0xFFFFFFFF,
        ).withOpacity(0.25), // Increased opacity for legibility
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      textTheme: _baseTextTheme.copyWith(
        displayLarge: _baseTextTheme.displayLarge?.copyWith(
          fontFamily: 'Outfit', // Futuristic Geometric Rounded
          letterSpacing: 1.2,
        ),
        bodyLarge: _baseTextTheme.bodyLarge?.copyWith(
          fontFamily: 'Roboto', // Clean modern sans
        ),
      ),
      appBarTheme: _baseAppBarTheme,
    );
  }

  // --- EXPANDED THEMES ---

  static ThemeData get _kaliLinuxTheme {
    // Hacker / Terminal Vibe
    const primary = Color(0xFF00FF00); // Terminal Green
    const bg = Color(0xFF000000);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: const Color(0xFF1B1B1B),
        surface: const Color(0xFF0D0D0D),
        onPrimary: AdaptiveTextEngine.compute(primary), // Auto-adaptive
        onSurface: const Color(0xFF00FF00), // Text is green too
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0D0D0D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp edges
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
    // Retro-Futuristic Dot Matrix
    const primary = Color(0xFFD71921); // Nothing Red
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

  static ThemeData get _appleGlassTheme {
    // Clean, Airy, Frosted
    const primary = Color(0xFF007AFF); // Apple Blue
    const bg = Color(0xFFF5F5F7); // Light Grey

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: const Color(0xFF5AC8FA),
        surface: Colors.white.withOpacity(0.8),
        onPrimary: AdaptiveTextEngine.compute(primary),
        onSurface: Colors.black,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.4), // Low opacity for glass effect
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(_lightTextTheme),
      appBarTheme: _baseAppBarTheme.copyWith(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }

  static ThemeData get _crimsonTheme {
    // Vampire / Gothic Luxury
    const primary = Color(0xFFDC143C); // Crimson
    const secondary = Color(0xFFFFD700); // Gold
    const bg = Color(0xFF050000); // Deepest Red/Black

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
    // 80s Synthwave
    const primary = Color(0xFF00FFFF); // Cyan
    const secondary = Color(0xFFFF00FF); // Magenta
    const bg = Color(0xFF0b0014); // Deep Purple space

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

  // --- HELPERS ---

  static ThemeData get _sunsetRetroTheme {
    // Vaporwave / Suneset: Orange to Purple gradient feel
    const primary = Color(0xFFFF9E80); // Deep Orange Accent
    const secondary = Color(0xFFEA80FC); // Purple Accent
    const bg = Color(0xFF2D1B2E); // Deep purple/brown

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
    // Zen / Forest: Green, Brown, Calm
    const primary = Color(0xFF66BB6A); // Light Green
    const secondary = Color(0xFF8D6E63); // Brown
    const bg = Color(0xFF1B261D); // Deep Jungle Green

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
          borderRadius: BorderRadius.circular(30), // Organic shape
          side: BorderSide(color: primary.withOpacity(0.2)),
        ),
      ),
      textTheme: GoogleFonts.quicksandTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _deepOceanTheme {
    // Abyssal: Deep Blue, Teal
    const primary = Color(0xFF00BFA5); // Teal Accent
    const secondary = Color(0xFF40C4FF); // Light Blue Accent
    const bg = Color(0xFF001018); // Almost black blue

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
    // Famous Dracula Color Palette
    const bg = Color(0xFF282A36);
    const primary = Color(0xFFBD93F9); // Purple
    const secondary = Color(0xFFFF79C6); // Pink
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
    // Monokai Pro Vibe
    const bg = Color(0xFF2D2A2E);
    const primary = Color(0xFFFC9867); // Orange
    const secondary = Color(0xFFFFD866); // Yellow
    const surface = Color(0xFF403E41);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: const Color(0xFFFF6188), // Red/Pink
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
    // Classic Grid/Sun Vibe
    const bg = Color(0xFF241734); // Dark violet
    const primary = Color(0xFFEB00FF); // Hot Pink
    const secondary = Color(0xFF00F0FF); // Cyan
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
          borderRadius: BorderRadius.circular(0), // Retro geometric
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
    const primary = Color(0xFFFF5722); // Solar Orange
    const secondary = Color(0xFFFFC107); // Amber
    const bg = Color(0xFF1A0A00); // Very Deep Orange Black

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
      textTheme: GoogleFonts.outfitTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _electricTundraTheme {
    const primary = Color(0xFF00E5FF); // Cyan
    const secondary = Color(0xFF2979FF); // Blue
    const bg = Color(0xFF001219); // Ice Deep Blue

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
    const primary = Color(0xFFE0E0E0); // Platinum
    const secondary = Color(0xFF00FF9D); // Hex Green
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
    const primary = Color(0xFF9C27B0); // Purple
    const secondary = Color(0xFFE91E63); // Pink
    const bg = Color(0xFF0D0014); // Darkest Purple

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
    const primary = Color(0xFFFF3D00); // Deep Orange
    const secondary = Color(0xFFD50000); // Red
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
    const primary = Color(0xFF00FF88); // Bloom Green
    const secondary = Color(0xFF88FF00); // Lime
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

  static ThemeData get _voidRiftTheme {
    const primary = Colors.white;
    const secondary = Color(0xFFE0E0E0);
    const bg = Color(0xFF000000);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF0A0A0A),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0A0A0A),
        elevation: 0,
        shape: const CircleBorder(side: BorderSide(color: Colors.white12)),
      ),
      textTheme: GoogleFonts.outfitTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  static ThemeData get _starlightEchoTheme {
    const primary = Color(0xFFB0BEC5); // Blue Grey
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

  static ThemeData get _aeroStreamTheme {
    const primary = Colors.white;
    const secondary = Color(0xFFB3E5FC); // Light Blue
    const bg = Color(0xFF000000);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212).withOpacity(0.9),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      textTheme: GoogleFonts.josefinSansTextTheme(_baseTextTheme),
      appBarTheme: _baseAppBarTheme,
    );
  }

  // --- HELPERS ---

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

  static const TextTheme _lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      color: Color(0xFF000000),
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      color: Color(0xFF000000),
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      color: Color(0xFF000000),
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      color: Color(0xFF000000),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: Color(0xFF000000),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: Color(0xFF000000),
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(color: Color(0xFF000000), fontSize: 16),
    bodyMedium: TextStyle(color: Color(0xFF424242), fontSize: 14),
    bodySmall: TextStyle(color: Color(0xFF757575), fontSize: 12),
  );
}

// Glassmorphic decoration helper
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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: blur,
          spreadRadius: -8,
        ),
      ],
    );
  }
}
