import 'package:flutter/material.dart';
import '../system/display_engine.dart';
export '../system/display_engine.dart';

/// NEBULA RESPONSIVE ENGINE (v2.0 - Powered by NADE)
/// Bridge class for backward compatibility with existing .w, .h, .sp extensions.
class Responsive {
  static void init(BuildContext context, {double scaleFactor = 1.0}) {
    DisplayEngine.init(context);
    DisplayEngine.setUserScale(scaleFactor);
  }

  static double w(double width) => DisplayEngine.w(width);
  static double h(double height) => DisplayEngine.h(height);
  static double sp(double fontSize) => DisplayEngine.sp(fontSize);
  static double r(double radius) => DisplayEngine.r(radius);

  /// Safe Area Padding Top
  static double get paddingTop => DisplayEngine.statusBarH;

  /// Safe Area Padding Bottom
  static double get paddingBottom => DisplayEngine.bottomBarH;

  /// Current Grid Columns based on width
  static int get gridColumns {
    if (DisplayEngine.screenW > 900) return 4;
    if (DisplayEngine.screenW > 600) return 3;
    return 2;
  }

  static double get horizontalPadding =>
      DisplayEngine.isTablet ? DisplayEngine.w(32) : DisplayEngine.w(20);
  static bool get isTablet => DisplayEngine.isTablet;
  static bool get hasNotch => DisplayEngine.statusBarH > 20;

  static double get screenWidth => DisplayEngine.screenW;
  static double get screenHeight => DisplayEngine.screenH;
}
