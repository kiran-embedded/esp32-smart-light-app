import 'package:flutter/material.dart';
import 'dart:math' as math;

/// NEBULA RESPONSIVE ENGINE
/// Dynamically scales UI components based on screen dimensions and pixel density.
/// Uses a base reference of 375x812 (standard iPhone/Android flagship).
class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double pixelRatio;
  static late double textScaleFactor;

  static late double scaleWidth;
  static late double scaleHeight;
  static late double scaleText;

  static void init(BuildContext context, {double scaleFactor = 1.0}) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    pixelRatio = _mediaQueryData.devicePixelRatio;
    textScaleFactor = _mediaQueryData.textScaleFactor;

    // Base dimensions for reference (simulating iPhone X / 11 Pro base)
    const double baseWidth = 375.0;
    const double baseHeight = 812.0;

    // Apply global scale factor
    scaleWidth = (screenWidth / baseWidth) * scaleFactor;
    scaleHeight = (screenHeight / baseHeight) * scaleFactor;

    // Scale text logic
    scaleText = math.min(scaleWidth, scaleHeight);

    // Tablet/Large Screen Optimization
    if (screenWidth > 600) {
      // On tablets, the raw scale might be too huge. Dampen it.
      // But respect the user's "Display Size" choice (scaleFactor).
      // If scaleFactor is high (Large), we let it grow more.
      scaleText = 1.0 + (scaleText - 1.0) * 0.6;
    }

    debugPrint(
      'NEBULA_RESPONSIVE: Init Screen: ${screenWidth}x${screenHeight} | ScaleFactor: $scaleFactor | Final W: ${scaleWidth.toStringAsFixed(2)}',
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
}
