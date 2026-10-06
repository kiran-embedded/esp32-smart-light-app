import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedNavIcon extends ConsumerWidget {
  final IconData icon;
  final bool isSelected;
  final String label;

  const AnimatedNavIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Base color logic
    final baseColor = isSelected
        ? theme.colorScheme.primary
        : Colors.white.withValues(alpha: 0.3);

    // Create the base icon widget
    Widget iconWidget = Icon(
      icon,
      size: 26,
      color: baseColor,
      shadows: isSelected
          ? [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ]
          : [],
    );

    if (!isSelected) {
      return iconWidget;
    }

    return iconWidget
        .animate()
        .moveY(begin: 5, end: 0, duration: 80.ms, curve: Curves.easeOutQuad)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.1, 1.1),
          duration: 80.ms,
        )
        .custom(
          duration: 80.ms,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -2 * value),
              child: child,
            );
          },
        );
  }
}
