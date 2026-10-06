import 'package:flutter/material.dart';

class SolidPanelContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const SolidPanelContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.only(bottom: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // We use the theme's card color directly.
    // If the cardColor is not provided explicitly by the theme, we fall back to a slightly elevated dark color.
    final color = theme.cardColor.computeLuminance() < 0.1 
        ? theme.cardColor 
        : const Color(0xFF141414);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.03), // very subtle border for depth without glass effect
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
