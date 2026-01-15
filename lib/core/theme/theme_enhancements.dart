import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Enhanced theme utilities for gradient text and auto-blending
class ThemeEnhancements {
  /// Get gradient colors for text based on theme
  static List<Color> getGradientColors(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.darkNeon:
        return [const Color(0xFF00E5FF), const Color(0xFF2979FF)];
      case AppThemeMode.cyberNeon:
        return [const Color(0xFF00FF9D), const Color(0xFFBC13FE)];
      case AppThemeMode.liquidGlass:
        return [const Color(0xFF2979FF), const Color(0xFF00E5FF)];
      case AppThemeMode.amoledCyberpunk:
        return [const Color(0xFFFF0055), const Color(0xFFE9FF00)];
      case AppThemeMode.darkSpace:
        return [const Color(0xFF00E676), const Color(0xFF00BCD4)];
      case AppThemeMode.neonTokyo:
        return [const Color(0xFF00FFFF), const Color(0xFFFF00FF)];
      case AppThemeMode.synthwave:
        return [const Color(0xFFEB00FF), const Color(0xFF00F0FF)];
      case AppThemeMode.solarFlare:
        return [const Color(0xFFFF5722), const Color(0xFFFFC107)];
      case AppThemeMode.electricTundra:
        return [const Color(0xFF00E5FF), const Color(0xFF2979FF)];
      case AppThemeMode.cyberBloom:
        return [const Color(0xFF00FF88), const Color(0xFF88FF00)];
      default:
        return [Colors.white, Colors.white70];
    }
  }

  /// Blend color with theme primary color
  static Color blendWithTheme(Color color, Color themePrimary, double ratio) {
    return Color.lerp(color, themePrimary, ratio.clamp(0.0, 1.0)) ?? color;
  }

  /// Get animated gradient shader
  static Shader getAnimatedGradientShader(
    Rect bounds,
    List<Color> colors,
    double animationValue,
  ) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: [
        0.0,
        0.5 + (animationValue * 0.3),
        1.0,
      ],
    ).createShader(bounds);
  }

  /// Create gradient text style
  static TextStyle gradientTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      foreground: Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.white70],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
    );
  }
}

/// Widget for gradient text that auto-blends with theme
class GradientText extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final TextAlign textAlign;

  const GradientText({
    super.key,
    required this.text,
    required this.colors,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 0,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: Colors.white,
        ),
      ),
    );
  }
}


