import 'package:flutter/material.dart';

/// ANIMA ENGINE
/// High-performance physics and curve definitions for Nebula Core.
class AnimationEngine {
  // --- CURVES ---

  // iPhone-like: Fast start, slow ease out
  static const Curve appleEase = Cubic(0.25, 0.1, 0.25, 1.0);

  // Butter: Smooth, consistent, no harsh stops
  static const Curve butter = Cubic(0.4, 0.0, 0.2, 1.0);

  // High Friction: Sticky, mechanical
  static const Curve mechanical = Cubic(0.2, 0.8, 0.2, 1.0);

  // --- TRANSITION BUILDERS ---

  static PageTransitionsTheme getTransitionTheme(dynamic type) {
    // We map the enum index or name to a builder
    // Since we don't want to import the provider here directly to avoid loops if not needed,
    // we'll genericize or just define standard builders.

    // For simplicity, we just return standard ones here, manual logic in main.dart handles the switch.
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );
  }
}
