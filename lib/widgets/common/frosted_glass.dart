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

  const FrostedGlass({
    super.key,
    required this.child,
    this.blur = 35, // Balanced for performance vs quality
    this.opacity = 0.18,
    this.saturation = 2.2,
    this.brightness = 1.0,
    this.radius = const BorderRadius.all(Radius.circular(28)),
    this.border,
    this.color,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (blur == 0) return _buildBody();

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          inner: ColorFilter.matrix([
            saturation,
            0,
            0,
            0,
            0,
            0,
            saturation,
            0,
            0,
            0,
            0,
            0,
            saturation,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(opacity),
        borderRadius: radius,
        border:
            border ??
            Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
      ),
      child: child,
    );
  }
}
