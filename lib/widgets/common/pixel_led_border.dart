import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/performance_provider.dart';
import 'dart:math' as math;

class PixelLedBorder extends ConsumerStatefulWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final List<Color> colors;
  final Duration duration;
  final bool isStatic;
  final bool enableInfiniteRainbow;

  const PixelLedBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.strokeWidth = 2.0,
    this.colors = const [
      Color(0xFF00E676), // Neon Green
      Color(0xFF00BCD4), // Cyan
      Color(0xFFD500F9), // Violet
      Colors.white, // W (RGBW)
    ],
    this.duration = const Duration(seconds: 3),
    this.isStatic = false,
    this.enableInfiniteRainbow = false,
  });

  @override
  ConsumerState<PixelLedBorder> createState() => _PixelLedBorderState();
}

class _PixelLedBorderState extends ConsumerState<PixelLedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _iteration = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener(_onAnimStatus); // Listen for completion
    _checkAnimation();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _iteration++;
      });
      _controller.reset();
      _controller.forward();
    }
  }

  void _checkAnimation() {
    final performanceMode = ref.read(performanceProvider);
    if (!widget.isStatic && !performanceMode) {
      if (!_controller.isAnimating)
        _controller.forward(); // Use forward + Listener
    } else {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(PixelLedBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If rainbow enabled, override colors with full spectrum + wrap
    final effectiveColors = widget.enableInfiniteRainbow
        ? const [
            Color(0xFFFF0000), // Red
            Color(0xFFFF7F00), // Orange
            Color(0xFFFFFF00), // Yellow
            Color(0xFF00FF00), // Green
            Color(0xFF0000FF), // Blue
            Color(0xFF4B0082), // Indigo
            Color(0xFF9400D3), // Violet
            Color(0xFFFF0000), // Red (Wrap)
          ]
        : widget.colors;

    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _PixelLedPainter(
          animation: _controller,
          borderRadius: widget.borderRadius,
          strokeWidth: widget.strokeWidth,
          colors: effectiveColors,
          isRainbow: widget.enableInfiniteRainbow,
          iteration: _iteration, // Pass iteration count
        ),
        child: widget.child,
      ),
    );
  }
}

class _PixelLedPainter extends CustomPainter {
  final Animation<double> animation;
  final double borderRadius;
  final double strokeWidth;
  final List<Color> colors;
  final bool isRainbow;
  final int iteration;

  _PixelLedPainter({
    required this.animation,
    required this.borderRadius,
    required this.strokeWidth,
    required this.colors,
    this.isRainbow = false,
    this.iteration = 0,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Ensure smooth endings if segmented

    // Dynamic Style based on Iteration
    // 0: Normal Sweep
    // 1: Tight Beam (Gap)
    // 2: Reverse Direction (Simulated)
    // 3: Breathing Sync
    final style = iteration % 4; // Cycle 4 styles

    List<double>? stops;
    double rotation = animation.value * 2 * math.pi;

    if (style == 1) {
      // Tight Beam logic
      stops = List.generate(colors.length + 1, (i) {
        // Compress stops to create gaps? Or simpler: Just shift colors
        return i / colors.length;
      });
      // Accelerate
      rotation = animation.value * 4 * math.pi;
    } else if (style == 2) {
      // Reverse
      rotation = -animation.value * 2 * math.pi;
    } else if (style == 3) {
      // Breathing rotation (sway)
      rotation =
          (math.sin(animation.value * math.pi * 2) * 0.8) +
          (animation.value * 2 * math.pi);
    }

    paint.shader = SweepGradient(
      colors: isRainbow
          ? colors
          : [...colors, colors.first], // Ensure wrap for custom colors too
      stops: stops,
      transform: GradientRotation(rotation),
    ).createShader(rect);

    // Softer "Water" Glow Layer
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isRainbow ? strokeWidth + 1.2 : strokeWidth * 1.8
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isRainbow ? 2.0 : 3.5);

    // If rainbow, reduce opacity of the glow
    if (isRainbow) {
      glowPaint.shader = paint.shader;
      glowPaint.color = Colors.white.withOpacity(0.15); // Much fainter
    } else {
      glowPaint.shader = paint.shader;
    }

    // Draw Glow first
    // Save layer to apply opacity to the glow if needed?
    // For performance, simple draw is better.
    if (isRainbow) {
      // Reduce intensity by drawing with a slightly transparent layer if needed,
      // or just rely on the stroke width difference.
      // Let's just draw.
      canvas.drawRRect(rrect, glowPaint);
    } else {
      canvas.drawRRect(rrect, glowPaint);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PixelLedPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value ||
      oldDelegate.colors != colors;
}
