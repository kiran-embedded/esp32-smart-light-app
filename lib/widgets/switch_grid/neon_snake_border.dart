import 'package:flutter/material.dart';

class NeonSnakeBorder extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final bool isInteracted;
  final bool isError;
  final bool isSyncing;
  final double borderRadius;

  const NeonSnakeBorder({
    super.key,
    required this.child,
    this.isActive = false,
    this.isInteracted = false,
    this.isError = false,
    this.isSyncing = false,
    this.borderRadius = 16,
  });

  @override
  State<NeonSnakeBorder> createState() => _NeonSnakeBorderState();
}

class _NeonSnakeBorderState extends State<NeonSnakeBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(NeonSnakeBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.isInteracted != widget.isInteracted ||
        oldWidget.isSyncing != widget.isSyncing) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.isActive) {
      _controller.duration = const Duration(
        seconds: 4,
      ); // Faster, more energetic
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else if (widget.isInteracted || widget.isSyncing) {
      _controller.duration = const Duration(seconds: 8);
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SnakePainter(
          animation: _controller,
          isActive: widget.isActive,
          isInteracted: widget.isInteracted,
          isSyncing: widget.isSyncing,
          isError: widget.isError,
          borderRadius: widget.borderRadius,
          gradientColors: [
            const Color(0xFF00FFFF), // Cyan
            const Color(0xFF007BFF), // Blue
            const Color(0xFFFF00FF), // Magenta
            const Color(0xFF00FFFF), // Wrap
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final Animation<double> animation;
  final bool isActive;
  final bool isInteracted;
  final bool isSyncing;
  final bool isError;
  final double borderRadius;
  final List<Color> gradientColors;

  _SnakePainter({
    required this.animation,
    required this.isActive,
    required this.isInteracted,
    required this.isSyncing,
    required this.isError,
    required this.borderRadius,
    required this.gradientColors,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Static Base Border
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isError
          ? Colors.red.withOpacity(0.3)
          : Colors.white.withOpacity(isActive ? 0.3 : 0.08);

    canvas.drawRRect(rrect, basePaint);

    // 2. Neon Snake (only if active/interacted/syncing)
    if (isActive || isInteracted || isSyncing) {
      final path = Path()..addRRect(rrect);
      final metrics = path.computeMetrics().first;

      final snakeLength = metrics.length * 0.2;
      final start = metrics.length * animation.value;

      final extractPath = metrics.extractPath(start, start + snakeLength);

      if (start + snakeLength > metrics.length) {
        extractPath.addPath(
          metrics.extractPath(0, (start + snakeLength) % metrics.length),
          Offset.zero,
        );
      }

      final snakePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            2.0 // Reduced from 3.0
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFFF0000), // Red
            Color(0xFFFF7F00), // Orange
            Color(0xFFFFFF00), // Yellow
            Color(0xFF00FF00), // Green
            Color(0xFF0000FF), // Blue
            Color(0xFF4B0082), // Indigo
            Color(0xFF9400D3), // Violet
            Color(0xFFFF0000), // Wrap Red
          ],
          stops: const [0.0, 0.14, 0.28, 0.42, 0.57, 0.71, 0.85, 1.0],
          transform: GradientRotation(animation.value * 2 * 3.14159),
        ).createShader(rect);

      final glowPaint1 = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            2.0 // Tighter inner glow
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
        ..color = (isActive
            ? const Color(0xAA00FFFF) // slightly more opaque, but thinner
            : const Color(0xAA007BFF));

      final glowPaint2 = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            4.0 // Reduced outer glow
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..color = (isActive
            ? const Color(0x33FF00FF) // Lower opacity for outer halo
            : const Color(0x3300E676));

      canvas.drawPath(extractPath, glowPaint2);
      canvas.drawPath(extractPath, glowPaint1);
      canvas.drawPath(extractPath, snakePaint);

      // 3. Energy Nodes (Corners)
      _drawEnergyNodes(canvas, size);
    }
  }

  void _drawEnergyNodes(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = gradientColors[0].withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final positions = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, 5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isInteracted != isInteracted ||
        oldDelegate.isSyncing != isSyncing ||
        oldDelegate.isError != isError;
  }
}
