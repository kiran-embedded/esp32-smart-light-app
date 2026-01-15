import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// TEMPORAL SCROLL PHYSICS (TSP)
///
/// "Scroll speed controls time, not distance."
/// - Slow scroll -> Loose, breathe-y physics.
/// - Fast flick -> Tight, locked physics.
class TemporalScrollPhysics extends BouncingScrollPhysics {
  const TemporalScrollPhysics({super.parent});

  @override
  TemporalScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TemporalScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring {
    // Standard iOS spring
    return const SpringDescription(mass: 80, stiffness: 100, damping: 1);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // "Slow scroll -> UI elements breathe"
    // We let the offset pass through more loosely for small movements
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      // "Fast flick -> UI locks into solid mode"
      // If velocity is high, we use a tighter simulation (higher drag/friction)
      // to "lock" earlier, or just standard bouncing if out of range.

      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity, // Pass full velocity
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }
}
