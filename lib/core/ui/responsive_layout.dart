import 'package:flutter/material.dart';
import 'dart:math' as math;

/// NEBULA RESPONSIVE ENGINE
/// Dynamically scales UI components based on screen dimensions and pixel density.
/// Uses a base reference of 375x812 (standard iPhone/Android flagship).
class Responsive {
  static MediaQueryData _mediaQueryData = const MediaQueryData();
  static double screenWidth = 375.0;
  static double screenHeight = 812.0;
  static double pixelRatio = 1.0;
  static double textScaleFactor = 1.0;

  static double scaleWidth = 1.0;
  static double scaleHeight = 1.0;
  static double scaleText = 1.0;

  static void init(
    BuildContext context, {
    double scaleMultiplier = 1.0,
    double fontMultiplier = 1.0,
  }) {
    // We allow re-initialization on context changes, but the first frame is always safe
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    pixelRatio = _mediaQueryData.devicePixelRatio;
    textScaleFactor = _mediaQueryData.textScaleFactor;

    // Base dimensions for reference
    const double baseWidth = 375.0;
    const double baseHeight = 812.0;

    scaleWidth = (screenWidth / baseWidth) * scaleMultiplier;
    scaleHeight = (screenHeight / baseHeight) * scaleMultiplier;

    // Scale text slightly less aggressively to avoid massive font on tablets
    scaleText = math.min(scaleWidth, scaleHeight) * fontMultiplier;
    if (screenWidth > 600) {
      // Tablet optimization: Don't let scale factor grow too large
      scaleText = 1.0 + (scaleText - 1.0) * 0.5;
    }

    debugPrint(
      'NEBULA_RESPONSIVE: Sync Active with Screen Size: ${screenWidth.toInt()}x${screenHeight.toInt()}',
    );
  }

  /// Adaptive Width
  static double w(double width) => width * scaleWidth;

  /// Adaptive Height
  static double h(double height) => height * scaleHeight;

  /// Adaptive Font Size
  static double sp(double fontSize) => fontSize * scaleText;

  /// Adaptive Spacing/Radius (Square scaling)
  static double r(double radius) => radius * scaleText;

  static double p(double padding) => padding * scaleText;

  /// Safe Area Padding Top
  static double get paddingTop => _mediaQueryData.padding.top;

  /// Safe Area Padding Bottom
  static double get paddingBottom => _mediaQueryData.padding.bottom;

  /// Current Grid Columns based on width
  static int get gridColumns {
    if (screenWidth > 900) return 4; // Desktop/Large Tablet
    if (screenWidth > 600) return 3; // Small Tablet
    return 2; // Phone
  }

  /// Adaptive Horizontal Padding
  static double get horizontalPadding {
    if (screenWidth > 600) return w(32);
    return w(20);
  }

  /// Check if device is a tablet
  static bool get isTablet => screenWidth > 600;

  /// Check if device has a notch
  static bool get hasNotch => _mediaQueryData.padding.top > 20;
}

/// Extension for easy access: 16.w, 10.sp, 20.r
extension ResponsiveExtension on num {
  double get w => Responsive.w(this.toDouble());
  double get h => Responsive.h(this.toDouble());
  double get sp => Responsive.sp(this.toDouble());
  double get r => Responsive.r(this.toDouble());
  double get p => Responsive.p(this.toDouble());
}
