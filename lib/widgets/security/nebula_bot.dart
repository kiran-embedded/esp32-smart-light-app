import 'package:flutter/material.dart';
import 'dart:math' as math;

class NebulaBotWidget extends StatefulWidget {
  final bool isAlarmActive;
  const NebulaBotWidget({super.key, required this.isAlarmActive});

  @override
  State<NebulaBotWidget> createState() => _NebulaBotWidgetState();
}

class _NebulaBotWidgetState extends State<NebulaBotWidget>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _BotPainter(
            animationValue: _controller.value,
            isAlarm: widget.isAlarmActive,
          ),
        );
      },
    );
  }
}

class _BotPainter extends CustomPainter {
  final double animationValue;
  final bool isAlarm;

  _BotPainter({required this.animationValue, required this.isAlarm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Hover effect
    final double hoverY = math.sin(animationValue * 2 * math.pi) * 10;
    final Offset bodyCenter = center.translate(0, hoverY);

    // 1. HEAD (Rounded Rect)
    paint.color = const Color(0xFF2D2D2D);
    final headRect = Rect.fromCenter(
      center: bodyCenter,
      width: 100,
      height: 80,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(24)),
      paint,
    );

    // 2. FACE (Screen)
    paint.color = const Color(0xFF1A1A1A);
    final faceRect = Rect.fromCenter(
      center: bodyCenter.translate(0, 5),
      width: 80,
      height: 40,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, const Radius.circular(12)),
      paint,
    );

    // 3. EYES
    if (isAlarm) {
      // Flashing alert eyes
      final double eyePulse = (math.sin(animationValue * 10 * math.pi) + 1) / 2;
      paint.color = Color.lerp(Colors.redAccent, Colors.amberAccent, eyePulse)!;

      // Angry/Alert eyebrows (simplified)
      canvas.drawCircle(bodyCenter.translate(-20, 5), 8, paint);
      canvas.drawCircle(bodyCenter.translate(20, 5), 8, paint);
    } else {
      paint.color = Colors.cyanAccent;
      canvas.drawCircle(bodyCenter.translate(-20, 5), 6, paint);
      canvas.drawCircle(bodyCenter.translate(20, 5), 6, paint);
    }

    // 4. SIREN LIGHT (on top of head)
    if (isAlarm) {
      final double sirenAlpha =
          (math.sin(animationValue * 15 * math.pi) + 1) / 2;
      paint.color = Colors.red.withOpacity(0.3 + 0.7 * sirenAlpha);
      final sirenBase = bodyCenter.translate(0, -45);
      canvas.drawCircle(sirenBase, 15, paint);

      paint.color = Colors.red;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: sirenBase, width: 20, height: 10),
          const Radius.circular(5),
        ),
        paint,
      );
    }

    // 5. BODY SIDES (Small stubs)
    paint.color = const Color(0xFF3D3D3D);
    canvas.drawCircle(bodyCenter.translate(-55, 10), 10, paint);
    canvas.drawCircle(bodyCenter.translate(55, 10), 10, paint);
  }

  @override
  bool shouldRepaint(covariant _BotPainter oldDelegate) => true;
}
