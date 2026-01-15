import 'package:flutter/material.dart';
export '../system/display_engine.dart';
import '../system/display_engine.dart';

/// NEBULA RESPONSIVE ENGINE (v2.0 - Powered by NADE)
/// Bridge class for backward compatibility with existing .w, .h, .sp extensions.
class Responsive {
  static void init(BuildContext context) => DisplayEngine.init(context);

  static double w(double width) => DisplayEngine.w(width);
  static double h(double height) => DisplayEngine.h(height);
  static double sp(double fontSize) => DisplayEngine.sp(fontSize);
  static double r(double radius) => DisplayEngine.r(radius);

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
    if (DisplayEngine.screenW > 900) return 4;
    if (DisplayEngine.screenW > 600) return 3;
    return 2;
  }

  static double get horizontalPadding => DisplayEngine.isTablet ? 32.w : 20.w;
  static bool get isTablet => DisplayEngine.isTablet;
  static bool get hasNotch => DisplayEngine.statusBarH > 20;
}
