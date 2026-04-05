import 'dart:math';
import 'package:flutter/material.dart';

/// ADAPTIVE TEXT ENGINE
/// Professional-grade contrast calculation engine.
/// Uses W3C WCAG 2.0 relative luminance formula for O(1) performance.
class AdaptiveTextEngine {
  /// Returns the optimal content color (White or Black) for a given background.
  ///
  /// [background] The background color to analyze.
  static Color compute(Color background) {
    // Calculate relative luminance
    // Formula: L = 0.2126 * R + 0.7152 * G + 0.0722 * B
    // Where R, G, B are normalized and gamma-corrected.
    double luminance = background.computeLuminance();

    // Use a slightly sensitive threshold for OLED black backgrounds
    // to ensure white text is always crisp.
    if (background.value == 0xFF000000) return Colors.white;

    // Threshold of 0.45 provides a more "modern" flip point
    // favoring white text on saturated primary colors.
    return luminance > 0.45 ? Colors.black87 : Colors.white;
  }

  /// Generates a high-contrast accent color for highlights.
  static Color accent(Color background) {
    double luminance = background.computeLuminance();
    return luminance > 0.5
        ? background.withRed(max(0, background.red - 50))
        : background.withRed(min(255, background.red + 50));
  }
}

/// Extension for easy usage: `myColor.adaptiveContentColor`
extension AdaptiveColorExtension on Color {
  /// Returns a highly visible text/icon color for this background color.
  Color get adaptiveContentColor => AdaptiveTextEngine.compute(this);

  /// Returns a high-contrast accent version of this color.
  Color get adaptiveAccentColor => AdaptiveTextEngine.accent(this);

  /// Returns a highly visible text/icon color with specific opacity.
  Color adaptiveContentColorWithOpacity(double opacity) {
    return AdaptiveTextEngine.compute(this).withOpacity(opacity);
  }
}
