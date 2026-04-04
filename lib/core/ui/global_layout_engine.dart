import 'dart:math' as math;

/// Quantum Constraint Solver Engine for Nebula Core UI
/// Uses iterative root-finding (Newton-Raphson inspired) to solve for the perfect UI fit.
class GlobalLayoutEngine {
  // Ideal heights (Fixed constants for the massive UI)
  static const double idealHeaderH = 100.0;
  static const double idealPillH = 32.0;
  static const double idealRoboH = 180.0;
  static const double idealTimeH = 75.0;
  static const double idealStatusH = 72.0;
  static const double idealActionsH = 80.0;

  static const double minGap = 6.0; // Lowered for quantum precision
  static const double maxGap = 40.0;

  /// Advanced Quantum Solver (Iterative Orchestration)
  static DashboardLayoutConfig solve({
    required double screenHeight,
    required double screenWidth,
    required double topPadding,
    required double bottomPadding,
    required double bottomNavHeight, // Critical to subtract for overlap fix
  }) {
    // Available safe area (Strict Quantum Viewport with 25px safety buffer)
    final double availableHeight =
        screenHeight - topPadding - bottomPadding - bottomNavHeight - 25.0;
    final double aspectRatio = screenHeight / screenWidth;

    // 1. Initial State (Unit Scale)
    double currentScale = 1.0;
    const int maxIterations = 5; // Newton-Raphson convergence limit

    // Weights (Priority of components)
    // 1.0 means full scaling, Lower means more resistance to shrinking
    final Map<String, double> priorities = {
      'header': 0.1, // Very resistant
      'pill': 0.2,
      'robo': 0.9, // Highly compressible
      'time': 0.5,
      'status': 0.7,
      'actions': 0.4,
    };

    // 2. Iterative Solving Logic
    for (int i = 0; i < maxIterations; i++) {
      double hHeader =
          idealHeaderH * (1.0 - (1.0 - currentScale) * priorities['header']!);
      double hPill =
          idealPillH * (1.0 - (1.0 - currentScale) * priorities['pill']!);
      double hRobo =
          idealRoboH * (1.0 - (1.0 - currentScale) * priorities['robo']!);
      double hTime =
          idealTimeH * (1.0 - (1.0 - currentScale) * priorities['time']!);
      double hStatus =
          idealStatusH * (1.0 - (1.0 - currentScale) * priorities['status']!);
      double hActions =
          idealActionsH * (1.0 - (1.0 - currentScale) * priorities['actions']!);

      double totalCompH = hHeader + hPill + hRobo + hTime + hStatus + hActions;
      double minTotalGaps = 6 * minGap;

      double occupied = totalCompH + minTotalGaps;

      if (occupied > availableHeight) {
        // Newton-Raphson approximation of the next scale
        double derivative =
            (idealHeaderH * priorities['header']!) +
            (idealPillH * priorities['pill']!) +
            (idealRoboH * priorities['robo']!) +
            (idealTimeH * priorities['time']!) +
            (idealStatusH * priorities['status']!) +
            (idealActionsH * priorities['actions']!);

        double delta = (occupied - availableHeight) / derivative;
        currentScale -= delta;
      } else {
        break; // Convergence reached
      }
    }

    // Final Clamp
    currentScale = currentScale.clamp(0.6, 1.0);

    // 3. Final Scale Assignments
    double headerScale = (1.0 - (1.0 - currentScale) * priorities['header']!)
        .clamp(0.9, 1.0);
    double pillScale = (1.0 - (1.0 - currentScale) * priorities['pill']!).clamp(
      0.9,
      1.0,
    );
    double roboScale = (1.0 - (1.0 - currentScale) * priorities['robo']!).clamp(
      0.65,
      1.0,
    );
    double timeScale = (1.0 - (1.0 - currentScale) * priorities['time']!).clamp(
      0.85,
      1.0,
    );
    double statusScale = (1.0 - (1.0 - currentScale) * priorities['status']!)
        .clamp(0.85, 1.0);
    double actionScale = (1.0 - (1.0 - currentScale) * priorities['actions']!)
        .clamp(0.85, 1.0);

    // 4. Gap Distribution (Weighted)
    final List<double> weights = [1.0, 1.2, 1.5, 1.5, 1.2, 1.0];
    final double totalWeight = weights.fold(0, (a, b) => a + b);

    double currentCompTotalH =
        (idealHeaderH * headerScale) +
        (idealPillH * pillScale) +
        (idealRoboH * roboScale) +
        (idealTimeH * timeScale) +
        (idealStatusH * statusScale) +
        (idealActionsH * actionScale);
    double gapRemainingH = math.max(0, availableHeight - currentCompTotalH);

    List<double> gaps = weights.map((w) {
      double g = (gapRemainingH * w) / totalWeight;
      return g.clamp(minGap, maxGap);
    }).toList();

    // Secondary Normalization for absolute safety
    double totalGaps = gaps.fold(0, (a, b) => a + b);
    if (totalGaps > gapRemainingH && gapRemainingH > 0) {
      double normalizationScale = gapRemainingH / totalGaps;
      gaps = gaps.map((g) => g * normalizationScale).toList();
    }

    // 5. Vertical Center Lock
    double usedHeight = currentCompTotalH + gaps.fold(0, (a, b) => a + b);
    double verticalOffset = math.max(0, (availableHeight - usedHeight) / 2);

    return DashboardLayoutConfig(
      gaps: gaps,
      headerScale: headerScale,
      pillScale: pillScale,
      roboScale: roboScale,
      timeScale: timeScale,
      statusScale: statusScale,
      actionScale: actionScale,
      verticalOffset: verticalOffset,
      aspectRatio: aspectRatio,
    );
  }
}

class DashboardLayoutConfig {
  final List<double> gaps;
  final double headerScale;
  final double pillScale;
  final double roboScale;
  final double timeScale;
  final double statusScale;
  final double actionScale;
  final double verticalOffset;
  final double aspectRatio;

  DashboardLayoutConfig({
    required this.gaps,
    required this.headerScale,
    required this.pillScale,
    required this.roboScale,
    required this.timeScale,
    required this.statusScale,
    required this.actionScale,
    required this.verticalOffset,
    required this.aspectRatio,
  });
}
