import 'package:flutter/material.dart';

class NeonSnakeBorder extends StatefulWidget {
  final Widget child;
  final bool isEnabled;
  final Color neonColor;
  final double borderWidth;
  final double borderRadius;

  const NeonSnakeBorder({
    super.key,
    required this.child,
    this.isEnabled = true,
    this.neonColor = Colors.cyanAccent,
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
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
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return widget.child;

    return CustomPaint(
      painter: _SnakePainter(
        animation: _controller,
        color: widget.neonColor,
        width: widget.borderWidth,
        radius: widget.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.borderWidth),
        child: widget.child,
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double width;
  final double radius;

  _SnakePainter({
    required this.animation,
    required this.color,
    required this.width,
    required this.radius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withOpacity(0.1),
          color.withOpacity(0.5),
          color,
          color.withOpacity(0.5),
          color.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
        startAngle: 0,
        endAngle: 3.14 * 2,
        transform: GradientRotation(animation.value * 3.14 * 2),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);

    // Add glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withOpacity(0.0),
          color.withOpacity(0.2),
          color.withOpacity(0.6),
          color.withOpacity(0.2),
          color.withOpacity(0.0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
        startAngle: 0,
        endAngle: 3.14 * 2,
        transform: GradientRotation(animation.value * 3.14 * 2),
      ).createShader(rect);

    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) => true;
}
