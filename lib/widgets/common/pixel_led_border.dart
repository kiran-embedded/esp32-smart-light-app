import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/display_settings_provider.dart';
import '../../providers/performance_provider.dart';
import 'dart:math' as math;

class PixelLedBorder extends ConsumerStatefulWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final List<Color> colors;
  final Duration duration;
  final NeonAnimationMode? mode;

  const PixelLedBorder({
    super.key,
    required this.child,
    this.borderRadius = 0,
    this.strokeWidth = 1.5,
    this.colors = const [Colors.blue, Colors.purple, Colors.red],
    this.duration = const Duration(seconds: 4),
    this.mode,
  });

  @override
  ConsumerState<PixelLedBorder> createState() => _PixelLedBorderState();
}

class _PixelLedBorderState extends ConsumerState<PixelLedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(PixelLedBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final performanceMode = ref.watch(performanceProvider);
    final displaySettings = ref.watch(displaySettingsProvider);
    final activeMode = widget.mode ?? displaySettings.neonAnimationMode;

    if (performanceMode) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.colors.first.withOpacity(0.5),
            width: widget.strokeWidth,
          ),
        ),
        child: widget.child,
      );
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _PixelLedPainter(
          animation: _controller,
          colors: widget.colors,
          strokeWidth: widget.strokeWidth,
          borderRadius: widget.borderRadius,
          mode: activeMode,
        ),
        child: widget.child,
      ),
    );
  }
}

class _PixelLedPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;
  final double strokeWidth;
  final double borderRadius;
  final NeonAnimationMode mode;

  _PixelLedPainter({
    required this.animation,
    required this.colors,
    required this.strokeWidth,
    required this.borderRadius,
    required this.mode,
  }) : super(repaint: animation);

  Path? _cachedPath;
  PathMetric? _cachedMetric;
  Size? _lastSize;

  void _updateCache(Size size) {
    if (_lastSize == size && _cachedPath != null) return;
    _lastSize = size;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    _cachedPath = Path()..addRRect(rrect);
    _cachedMetric = _cachedPath!.computeMetrics().first;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _updateCache(size);
    final path = _cachedPath!;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.5
      ..maskFilter = null; // BUG FIXED: Removed continuous blur filter which caused neon bleeding and CPU raster jitter

    final laserPointPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 4.0
      ..strokeCap = StrokeCap.round; // Sharp laser point tip

    switch (mode) {
      case NeonAnimationMode.sweep:
        _paintSweep(canvas, path, paint, glowPaint, size);
        break;
      case NeonAnimationMode.dotRunner:
        _paintDotRunner(canvas, _cachedMetric!, paint, glowPaint, size);
        break;
      case NeonAnimationMode.comet:
        _paintComet(canvas, _cachedMetric!, paint, glowPaint, size);
        break;
      case NeonAnimationMode.pulse:
        _paintPulse(canvas, path, paint, glowPaint, size);
        break;
      case NeonAnimationMode.strobe:
        _paintStrobe(canvas, path, paint, glowPaint, size);
        break;
      case NeonAnimationMode.rainbow:
        _paintRainbow(canvas, path, paint, glowPaint, size);
        break;
      case NeonAnimationMode.autoChange:
        _paintAutoChange(canvas, path, _cachedMetric!, paint, glowPaint, size);
        break;
      case NeonAnimationMode.thinLine:
        _paintThinLine(canvas, path, paint, size);
        break;
    }
  }

  void _paintThinLine(Canvas canvas, Path path, Paint paint, Size size) {
    final gradient = SweepGradient(
      colors: colors,
      transform: GradientRotation(animation.value * 2 * math.pi),
    );
    paint.shader = gradient.createShader(Offset.zero & size);
    paint.strokeWidth = 1.0; // Force 1px
    canvas.drawPath(path, paint);
  }

  void _paintSweep(
    Canvas canvas,
    Path path,
    Paint paint,
    Paint glowPaint,
    Size size,
  ) {
    final gradient = SweepGradient(
      colors: colors,
      stops: List.generate(colors.length, (i) => i / (colors.length - 1)),
      transform: GradientRotation(animation.value * 2 * math.pi),
    );

    paint.shader = gradient.createShader(Offset.zero & size);
    glowPaint.shader = gradient.createShader(Offset.zero & size);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Render Laser Point dot at leading edge of gradient
    laserPointPaint.color = Colors.white;
    // Add small moving dot representation for Laser logic
    final laserPosOffset = (animation.value * 2 * math.pi);
    // Draw directly via path properties handled in Comet or Sweep if necessary.
    // In Sweep, the trailing end of rotation is bright.

  }

  void _paintDotRunner(
    Canvas canvas,
    PathMetric pathMetric,
    Paint paint,
    Paint glowPaint,
    Size size,
  ) {
    final length = pathMetric.length;
    final dotPos = animation.value * length;

    for (int i = 0; i < 3; i++) {
      final offset = (i * length / 3 + dotPos) % length;
      final extractPath = pathMetric.extractPath(offset - 20, offset + 20);

      paint.color = colors[i % colors.length];
      glowPaint.color = colors[i % colors.length].withOpacity(0.5);

      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, paint);
    }
  }

  void _paintComet(
    Canvas canvas,
    PathMetric pathMetric,
    Paint paint,
    Paint glowPaint,
    Size size,
  ) {
    final length = pathMetric.length;
    final pos = animation.value * length;

    final extractPath = pathMetric.extractPath(pos - 60, pos);
    
    // Laser point dot trailing the comet
    final laserDotPath = pathMetric.extractPath(pos - 2, pos);

    final cometPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [colors.first.withOpacity(0), colors.first],
      ).createShader(Offset.zero & size);

    canvas.drawPath(extractPath, cometPaint);
    
    final dotPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3.0 // Emphasize the front laser point
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
      
    canvas.drawPath(laserDotPath, dotPaint);
  }

  void _paintPulse(
    Canvas canvas,
    Path path,
    Paint paint,
    Paint glowPaint,
    Size size,
  ) {
    final pulse = 0.5 + (math.sin(animation.value * 2 * math.pi) * 0.5);
    paint.color = colors.first.withOpacity(pulse);
    glowPaint.color = colors.first.withOpacity(pulse * 0.5);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _paintStrobe(
    Canvas canvas,
    Path path,
    Paint paint,
    Paint glowPaint,
    Size size,
  ) {
    if ((animation.value * 10).floor() % 2 == 0) {
      paint.color = colors.first;
      glowPaint.color = colors.first.withOpacity(0.5);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  void _paintRainbow(
    Canvas canvas,
    Path path,
    Paint paint,
    Paint glowPaint,
    Size size,
  ) {
    final rainbowColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];
    final gradient = SweepGradient(
      colors: rainbowColors,
      transform: GradientRotation(animation.value * 2 * math.pi),
    );
    paint.shader = gradient.createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  void _paintAutoChange(
    Canvas canvas,
    Path path,
    PathMetric pathMetric,
    Paint paint,
    Paint glowPaint,
    Size size,
  ) {
    final modeIndex = (animation.value * 6).floor() % 6;
    switch (modeIndex) {
      case 0:
        _paintSweep(canvas, path, paint, glowPaint, size);
        break;
      case 1:
        _paintDotRunner(canvas, pathMetric, paint, glowPaint, size);
        break;
      case 2:
        _paintComet(canvas, pathMetric, paint, glowPaint, size);
        break;
      case 3:
        _paintPulse(canvas, path, paint, glowPaint, size);
        break;
      case 4:
        _paintStrobe(canvas, path, paint, glowPaint, size);
        break;
      case 5:
        _paintRainbow(canvas, path, paint, glowPaint, size);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PixelLedPainter oldDelegate) => true;
}
