import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FrostedGlass extends ConsumerWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double saturation;
  final double brightness;
  final BorderRadius radius;
  final Border? border;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool disableBlur; // manual override

  const FrostedGlass({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.1, // Unused but kept for API compatibility
    this.saturation = 1.0,
    this.brightness = 1.0,
    this.radius = const BorderRadius.all(Radius.circular(28)),
    this.border,
    this.color,
    this.padding,
    this.width,
    this.height,
    this.disableBlur = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        // Solid, theme-blended color instead of blur
        color: color ?? const Color(0xFF121418),
        borderRadius: radius,
        border:
            border ??
            Border.all(
              color: (color ?? Colors.white).withOpacity(0.05),
              width: 1.0,
            ),
      ),
      child: child,
    );
  }
}
