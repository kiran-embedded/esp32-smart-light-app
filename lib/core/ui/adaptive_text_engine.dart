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

    // Threshold of 0.5 is standard, but 0.6 provides better accessibility
    // for "middle" colors ensuring text pops more often as black.
    // However, for neon apps, we often want white text on saturated colors.
    // Using 0.5 as the baseline breakpoint.
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Extension for easy usage: `myColor.adaptiveContentColor`
extension AdaptiveColorExtension on Color {
  /// Returns a highly visible text/icon color for this background color.
  Color get adaptiveContentColor => AdaptiveTextEngine.compute(this);

  /// Returns a highly visible text/icon color with specific opacity.
  Color adaptiveContentColorWithOpacity(double opacity) {
    return AdaptiveTextEngine.compute(this).withOpacity(opacity);
  }
}
