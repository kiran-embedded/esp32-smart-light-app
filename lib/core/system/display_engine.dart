import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// NEBULA ADVANCED DISPLAY ENGINE (NADE)
/// An Unreal Engine inspired UI scaling and visual management system.
class DisplayEngine {
  static late MediaQueryData _data;
  static double _width = 375;
  static double _height = 812;
  static double _pixelRatio = 1.0;
  static double _textScale = 1.0;

  // Scaling factors
  static double _scaleW = 1.0;
  static double _scaleH = 1.0;
  static double _scaleMin = 1.0;

  // Hardware Diagnostic Info
  static String deviceModel = "Unknown";
  static String cpuHardware = "N/A";
  static String androidVersion = "N/A";

  // Visual state
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Initialize the engine with device data
  static void init(BuildContext context) async {
    _data = MediaQuery.of(context);
    _width = _data.size.width;
    _height = _data.size.height;
    _pixelRatio = _data.devicePixelRatio;
    _textScale = _data.textScaleFactor.clamp(
      0.8,
      1.1,
    ); // Clamp to prevent huge text

    // Reference design: iPhone Pro (Industry Standard)
    const double refW = 390.0;
    const double refH = 844.0;

    _scaleW = _width / refW;
    _scaleH = _height / refH;

    // Dynamic smoothing for text and radius to avoid "huge" UI on tablets
    _scaleMin = math.min(_scaleW, _scaleH);

    // Unreal-style adaptive text scaling
    if (_width > 600) {
      _scaleMin = 1.0 + (_scaleMin - 1.0) * 0.65;
    } else {
      // For phones, prevent over-scaling on high density small screens
      _scaleMin = _scaleMin.clamp(0.85, 1.15);
    }

    // Fetch Hardware Info
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
        cpuHardware = androidInfo.hardware;
        androidVersion = "Android ${androidInfo.version.release}";
      }
    } catch (e) {
      debugPrint("NADE_DIAGNOSTIC_ERROR: $e");
    }

    _initialized = true;

    debugPrint(
      'DISPLAY_ENGINE: Link Start. Architecture: ${_width.toInt()}x${_height.toInt()} @ ${_pixelRatio}x',
    );
  }

  static double _userScale = 1.0;
  static double _userDensity = 1.0;

  static void setUserScale(double scale) {
    _userScale = scale;
  }

  static void setUserDensity(double density) {
    _userDensity = density;
  }

  // W/H/R/P now affected by density (DPI)
  static double w(double val) => val * _scaleW * _userDensity;
  static double h(double val) => val * _scaleH * _userDensity;

  // SP affects text. It combines Density (DPI) AND Font Scale.
  static double sp(double val) =>
      val * _scaleMin * _textScale * _userScale * _userDensity;

  static double r(double val) => val * _scaleMin * _userDensity;
  static double p(double val) => val * _scaleMin * _userDensity;

  static double get screenW => _width;
  static double get screenH => _height;
  static double get statusBarH => _data.padding.top;
  static double get bottomBarH => _data.padding.bottom;
  static double get aspectRatio => _width / _height;

  static double get scaleW => _scaleW;
  static double get scaleH => _scaleH;
  static double get scaleMin => _scaleMin;

  static bool get isTablet => _width > 600;
  static bool get isUltraWide => aspectRatio > 2.1;
  static bool get isSmallPhone => _width < 360;

  static double get pillHeight => h(56).clamp(48, 72);
  static double get pillRadius => r(28);
}

/// Global extension for immediate access
extension DisplayEngineExtension on num {
  double get w => DisplayEngine.w(this.toDouble());
  double get h => DisplayEngine.h(this.toDouble());
  double get sp => DisplayEngine.sp(this.toDouble());
  double get r => DisplayEngine.r(this.toDouble());
  double get p => DisplayEngine.p(this.toDouble());
}
