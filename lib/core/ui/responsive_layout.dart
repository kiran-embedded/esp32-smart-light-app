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

  static double get paddingTop => DisplayEngine.statusBarH;
  static double get paddingBottom => DisplayEngine.bottomBarH;
  static double get screenWidth => DisplayEngine.screenW;
  static double get screenHeight => DisplayEngine.screenH;

  static int get gridColumns {
    if (DisplayEngine.screenW > 900) return 4;
    if (DisplayEngine.screenW > 600) return 3;
    return 2;
  }

  static double get horizontalPadding => DisplayEngine.isTablet ? 32.w : 20.w;
  static bool get isTablet => DisplayEngine.isTablet;
  static bool get hasNotch => DisplayEngine.statusBarH > 20;
}
