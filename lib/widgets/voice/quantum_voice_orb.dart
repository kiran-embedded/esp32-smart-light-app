import 'dart:math' as math;
import 'package:flutter/material.dart';

class QuantumVoiceOrb extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final bool isSuccess;

  const QuantumVoiceOrb({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.isSuccess,
  });

  @override
  State<QuantumVoiceOrb> createState() => _QuantumVoiceOrbState();
}

class _QuantumVoiceOrbState extends State<QuantumVoiceOrb>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glitterController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _glitterController]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _SiriWavePainter(
            phase: _controller.value * 2 * math.pi,
            amplitude: widget.isListening
                ? 0.9
                : (widget.isProcessing ? 0.4 : 0.1),
            isSuccess: widget.isSuccess,
            glitterValue: _glitterController.value,
          ),
        );
      },
    );
  }
}

class _SiriWavePainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final bool isSuccess;
  final double glitterValue;

  _SiriWavePainter({
    required this.phase,
    required this.amplitude,
    required this.isSuccess,
    required this.glitterValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 4;

    final List<Color> colors = isSuccess
        ? [Colors.greenAccent, Colors.cyanAccent, Colors.lightGreenAccent]
        : [
            Colors.cyanAccent,
            Colors.purpleAccent,
            Colors.blueAccent,
            Colors.indigoAccent,
          ];

    // 1. Draw Waves
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i].withOpacity(0.3 - (i * 0.05))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      final path = Path();
      final points = 80;
      final waveOffset = i * math.pi / 2;

      for (int j = 0; j <= points; j++) {
        final angle = (j / points) * 2 * math.pi;
        final wave =
            math.sin(angle * (2 + i) + phase + waveOffset) * 20 * amplitude;
        final r = radius + wave;

        final x = centerX + r * math.cos(angle);
        final y = centerY + r * math.sin(angle);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // 2. Draw Glitter Particles
    final ran = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final pAngle = ran.nextDouble() * 2 * math.pi;
      final pDist =
          (radius * 0.8) + (ran.nextDouble() * radius * 0.5 * amplitude);
      final pSize = ran.nextDouble() * 2 + 1;
      final pOpacity = (math.sin(glitterValue * 2 * math.pi + i) + 1) / 2;

      final px = centerX + pDist * math.cos(pAngle + phase * 0.2);
      final py = centerY + pDist * math.sin(pAngle + phase * 0.2);

      final pPaint = Paint()
        ..color = Colors.white.withOpacity(pOpacity * 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), pSize, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiriWavePainter oldDelegate) => true;
}
