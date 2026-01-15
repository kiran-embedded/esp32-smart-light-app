import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../core/ui/responsive_layout.dart';

class HeroVoltageMeter extends ConsumerWidget {
  const HeroVoltageMeter({super.key});

  Color _getVoltageColor(double voltage) {
    if (voltage <= 0) return Colors.grey;
    if (voltage < 180) return Colors.redAccent;
    if (voltage < 200) return Colors.orangeAccent;
    if (voltage >= 200 && voltage <= 250) return Colors.greenAccent;
    if (voltage > 250) return Colors.redAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final displaySettings = ref.watch(displaySettingsProvider);
    final voltage = liveInfo.acVoltage;
    final voltageColor = _getVoltageColor(voltage);
    final scale = displaySettings.displayScale;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 40 * scale),
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(40 * scale),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gauge Painter
          SizedBox(
            width: 300 * scale,
            height: 220 * scale,
            child: CustomPaint(
              painter: _ArcGaugePainter(
                voltage: voltage,
                color: voltageColor,
                scale: scale,
              ),
            ),
          ),
          // Center Text
          Positioned(
            top: 60 * scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.white.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    voltage.toStringAsFixed(0),
                    style: GoogleFonts.outfit(
                      fontSize: 84 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: voltageColor.withOpacity(0.4),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'VOLTS AC',
                  style: GoogleFonts.outfit(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w800,
                    color: voltageColor.withOpacity(0.7),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildGridStatus(voltage, scale, voltageColor),
              ],
            ),
          ),

          // Small Electric Waves (Pulse Animation)
          Positioned(
            bottom: 20 * scale,
            child: _ElectricWavePulse(color: voltageColor, scale: scale),
          ),
        ],
      ),
    );
  }

  Widget _buildGridStatus(double voltage, double scale, Color color) {
    final isStable = voltage >= 200 && voltage <= 250;
    final status = isStable
        ? 'LIVE GRID STATUS – STABLE'
        : (voltage < 180 ? 'CRITICAL LOW VOLTAGE' : 'VOLTAGE FLUCTUATION');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingPulse(
            color: isStable ? Colors.greenAccent : Colors.redAccent,
            scale: scale,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: GoogleFonts.outfit(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double voltage;
  final Color color;
  final double scale;

  _ArcGaugePainter({
    required this.voltage,
    required this.color,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    final radius = size.width * 0.45;
    const startAngle = 1.0 * math.pi;
    const sweepAngle = 1.0 * math.pi;

    // Background Arc
    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      basePaint,
    );

    // Ticks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2 * scale;

    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * (i / 10));
      final innerP =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - 15 * scale);
      final outerP =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius + 5 * scale);
      canvas.drawLine(innerP, outerP, tickPaint);
    }

    // Active Progress Arc
    final progress = (voltage / 300).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.1), color],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20 * scale
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 8 * scale);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) =>
      oldDelegate.voltage != voltage || oldDelegate.color != color;
}

class _BlinkingPulse extends StatefulWidget {
  final Color color;
  final double scale;
  const _BlinkingPulse({required this.color, required this.scale});

  @override
  State<_BlinkingPulse> createState() => _BlinkingPulseState();
}

class _BlinkingPulseState extends State<_BlinkingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8 * widget.scale,
        height: 8 * widget.scale,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color,
              blurRadius: 8 * widget.scale,
              spreadRadius: 2 * widget.scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _ElectricWavePulse extends StatefulWidget {
  final Color color;
  final double scale;
  const _ElectricWavePulse({required this.color, required this.scale});

  @override
  State<_ElectricWavePulse> createState() => _ElectricWavePulseState();
}

class _ElectricWavePulseState extends State<_ElectricWavePulse>
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
          size: Size(200 * widget.scale, 40 * widget.scale),
          painter: _WavePainter(
            animation: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  _WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3 * (1 - animation))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height / 2 +
            math.sin(
                  (i / size.width * 2 * math.pi) + (animation * 2 * math.pi),
                ) *
                10 *
                animation,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
