import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedGlass extends StatelessWidget {
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
  final bool disableBlur; // optimization for lists

  const FrostedGlass({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.18,
    this.saturation = 2.2,
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
  Widget build(BuildContext context) {
    if (blur == 0 || disableBlur) return _buildBody();

    return ClipRRect(
      borderRadius: radius,
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // If blur is disabled, increase opacity slightly to ensure legibility
    final double effectiveOpacity = disableBlur
        ? (opacity + 0.15).clamp(0.0, 0.95)
        : opacity;

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(effectiveOpacity),
        borderRadius: radius,
        border:
            border ??
            Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
      ),
      child: child,
    );
  }
}
