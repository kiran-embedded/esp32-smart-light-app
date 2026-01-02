import 'dart:math' as math;

class TestResponsive {
  static double screenWidth = 375.0;
  static double screenHeight = 812.0;

  static double scaleWidth = 1.0;
  static double scaleHeight = 1.0;
  static double scaleText = 1.0;

  static void init(double w, double h) {
    screenWidth = w;
    screenHeight = h;

    const double baseWidth = 375.0;
    const double baseHeight = 812.0;

    scaleWidth = screenWidth / baseWidth;
    scaleHeight = screenHeight / baseHeight;

    scaleText = math.min(scaleWidth, scaleHeight);
    if (screenWidth > 600) {
      scaleText = 1.0 + (scaleText - 1.0) * 0.5;
    }
  }

  static double w(double width) => width * scaleWidth;
  static double h(double height) => height * scaleHeight;
  static double sp(double fontSize) => fontSize * scaleText;
  static double r(double radius) => radius * scaleText;

  static int get gridColumns {
    if (screenWidth > 900) return 4;
    if (screenWidth > 600) return 3;
    return 2;
  }
}

void main() {
  final testRes = [
    [375.0, 812.0], // Base (iPhone 13 mini / Pixel 4)
    [390.0, 844.0], // iPhone 14
    [430.0, 932.0], // iPhone 14 Pro Max
    [411.0, 891.0], // Pixel 6
    [768.0, 1024.0], // iPad mini
    [1024.0, 1366.0], // iPad Pro 12.9
  ];

  print('Resolution | ScaleW | ScaleH | ScaleT | Columns | 100.w | 20.sp');
  print('-----------|--------|--------|--------|---------|-------|------');

  for (var res in testRes) {
    TestResponsive.init(res[0], res[1]);
    print(
      '${res[0].toString().padRight(5)}x${res[1].toString().padRight(5)} | '
      '${TestResponsive.scaleWidth.toStringAsFixed(3)} | '
      '${TestResponsive.scaleHeight.toStringAsFixed(3)} | '
      '${TestResponsive.scaleText.toStringAsFixed(3)} | '
      '${TestResponsive.gridColumns.toString().padRight(7)} | '
      '${TestResponsive.w(100).toStringAsFixed(1).padRight(5)} | '
      '${TestResponsive.sp(20).toStringAsFixed(1)}',
    );
  }
}
