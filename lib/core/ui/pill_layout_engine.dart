import 'dart:math' as math;

/// Advanced Layout Engine for the Status Pill (Dynamic Island)
/// Uses mathematical models to calculate precise dimensions and opacities.
class PillLayoutEngine {
  // Constants for the "Massive" design system
  static const double minHeight = 72.0;
  static const double maxHeight = 135.0;
  static const double minWidthFactor = 0.90;
  static const double maxWidthFactor = 0.94;
  static const double minRadius = 36.0;
  static const double maxRadius = 40.0;

  /// Calculates pill dimensions based on expansion progress [0.0 - 1.0]
  static PillDimensions calculate(double progress, double screenWidth) {
    // Normalize sigmoid to ensure it's exactly 0 at 0 and 1 at 1
    final double s0 = _sigmoidRaw(0.0);
    final double s1 = _sigmoidRaw(1.0);
    final double easedProgress = (_sigmoidRaw(progress) - s0) / (s1 - s0);

    final double height = minHeight + (maxHeight - minHeight) * easedProgress;
    final double width =
        screenWidth *
        (minWidthFactor + (maxWidthFactor - minWidthFactor) * easedProgress);
    final double radius = minRadius + (maxRadius - minRadius) * easedProgress;

    // Content Opacity Mapping
    final double collapsedOpacity = math.max(0, 1.0 - progress * 2.5);
    final double expandedOpacity = math.max(0, (progress - 0.4) * 1.66);

    return PillDimensions(
      width: width,
      height: height,
      radius: radius,
      collapsedOpacity: collapsedOpacity,
      expandedOpacity: expandedOpacity,
      progress: progress,
    );
  }

  static double _sigmoidRaw(double x) {
    const double k = 10.0;
    const double x0 = 0.5;
    return 1.0 / (1.0 + math.exp(-k * (x - x0)));
  }

  /// Calculates dynamic gravity/spring force for physics-based animations
  /// Uses a second-order differential equation approximation (Calculus)
  static double calculateSpringForce(double velocity, double displacement) {
    const double stiffness = 180.0;
    const double damping = 25.0;
    return -stiffness * displacement - damping * velocity;
  }
}

class PillDimensions {
  final double width;
  final double height;
  final double radius;
  final double collapsedOpacity;
  final double expandedOpacity;
  final double progress;

  PillDimensions({
    required this.width,
    required this.height,
    required this.radius,
    required this.collapsedOpacity,
    required this.expandedOpacity,
    required this.progress,
  });
}
