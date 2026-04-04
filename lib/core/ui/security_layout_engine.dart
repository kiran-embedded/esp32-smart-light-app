import 'dart:math' as math;

/// Quantum Constraint Solver Engine for Nebula Security Hub
class SecurityLayoutEngine {
  // Ideal heights for the Security Hub components
  static const double idealHeaderH = 80.0;
  static const double idealMasterCardH = 260.0;
  static const double idealLabelH = 40.0;
  static const double idealSensorGridH = 280.0; // Target for 2x2 or 2x3 grid
  static const double idealPanicH = 80.0;

  static const double minGap = 8.0;
  static const double maxGap = 32.0;

  static SecurityLayoutConfig solve({
    required double screenHeight,
    required double screenWidth,
    required double topPadding,
    required double bottomPadding,
    required double bottomNavHeight,
    required int sensorCount,
  }) {
    // Available safe area with safety margin
    final double availableHeight =
        screenHeight - topPadding - bottomPadding - bottomNavHeight - 30.0;

    double currentScale = 1.0;
    const int maxIterations = 5;

    // Weights: Lower means more resistant to shrinking
    final Map<String, double> priorities = {
      'header': 0.1,
      'master': 0.4,
      'label': 0.2,
      'grid': 0.8, // Most compressible
      'panic': 0.3,
    };

    for (int i = 0; i < maxIterations; i++) {
      double hHeader =
          idealHeaderH * (1.0 - (1.0 - currentScale) * priorities['header']!);
      double hMaster =
          idealMasterCardH *
          (1.0 - (1.0 - currentScale) * priorities['master']!);
      double hLabel =
          idealLabelH * (1.0 - (1.0 - currentScale) * priorities['label']!);
      double hGrid =
          idealSensorGridH * (1.0 - (1.0 - currentScale) * priorities['grid']!);
      double hPanic =
          idealPanicH * (1.0 - (1.0 - currentScale) * priorities['panic']!);

      double totalCompH = hHeader + hMaster + hLabel + hGrid + hPanic;
      double minTotalGaps = 5 * minGap;
      double occupied = totalCompH + minTotalGaps;

      if (occupied > availableHeight) {
        double derivative =
            (idealHeaderH * priorities['header']!) +
            (idealMasterCardH * priorities['master']!) +
            (idealLabelH * priorities['label']!) +
            (idealSensorGridH * priorities['grid']!) +
            (idealPanicH * priorities['panic']!);

        double delta = (occupied - availableHeight) / derivative;
        currentScale -= delta;
      } else {
        break;
      }
    }

    currentScale = currentScale.clamp(0.65, 1.0);

    double headerScale = (1.0 - (1.0 - currentScale) * priorities['header']!)
        .clamp(0.9, 1.0);
    double masterScale = (1.0 - (1.0 - currentScale) * priorities['master']!)
        .clamp(0.8, 1.0);
    double labelScale = (1.0 - (1.0 - currentScale) * priorities['label']!)
        .clamp(0.9, 1.0);
    double gridScale = (1.0 - (1.0 - currentScale) * priorities['grid']!).clamp(
      0.65,
      1.0,
    );
    double panicScale = (1.0 - (1.0 - currentScale) * priorities['panic']!)
        .clamp(0.85, 1.0);

    double currentCompTotalH =
        (idealHeaderH * headerScale) +
        (idealMasterCardH * masterScale) +
        (idealLabelH * labelScale) +
        (idealSensorGridH * gridScale) +
        (idealPanicH * panicScale);

    double gapRemainingH = math.max(0, availableHeight - currentCompTotalH);
    final List<double> weights = [1.0, 1.5, 1.0, 1.2, 1.0];
    final double totalWeight = weights.fold(0, (a, b) => a + b);

    List<double> gaps = weights.map((w) {
      double g = (gapRemainingH * w) / totalWeight;
      return g.clamp(minGap, maxGap);
    }).toList();

    double usedHeight = currentCompTotalH + gaps.fold(0, (a, b) => a + b);
    double verticalOffset = math.max(0, (availableHeight - usedHeight) / 2);

    return SecurityLayoutConfig(
      gaps: gaps,
      headerScale: headerScale,
      masterScale: masterScale,
      labelScale: labelScale,
      gridScale: gridScale,
      panicScale: panicScale,
      verticalOffset: verticalOffset,
    );
  }
}

class SecurityLayoutConfig {
  final List<double> gaps;
  final double headerScale;
  final double masterScale;
  final double labelScale;
  final double gridScale;
  final double panicScale;
  final double verticalOffset;

  SecurityLayoutConfig({
    required this.gaps,
    required this.headerScale,
    required this.masterScale,
    required this.labelScale,
    required this.gridScale,
    required this.panicScale,
    required this.verticalOffset,
  });
}
