import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/performance_provider.dart';
import '../../providers/switch_settings_provider.dart';

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
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceMode = ref.watch(performanceProvider);
    final blurEnabled = ref.watch(switchSettingsProvider).blurEffectsEnabled;
    final bool effectivelyDisabled =
        disableBlur || performanceMode || !blurEnabled;

    if (blur == 0 || effectivelyDisabled)
      return _buildBody(effectivelyDisabled);

    return ClipRRect(
      borderRadius: radius,
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: _buildBody(effectivelyDisabled),
        ),
      ),
    );
  }

  Widget _buildBody(bool effectivelyDisabled) {
    // If blur is disabled, increase opacity slightly to ensure legibility
    final double effectiveOpacity = effectivelyDisabled
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
