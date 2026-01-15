import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/performance_provider.dart';
import '../../providers/switch_settings_provider.dart';

class NebulaSpaceBackground extends ConsumerStatefulWidget {
  final Widget child;
  const NebulaSpaceBackground({super.key, required this.child});

  @override
  ConsumerState<NebulaSpaceBackground> createState() =>
      _NebulaSpaceBackgroundState();
}

class _NebulaSpaceBackgroundState extends ConsumerState<NebulaSpaceBackground> {
  @override
  Widget build(BuildContext context) {
    final performanceMode = ref.watch(performanceProvider);
    final blurEnabled = ref.watch(switchSettingsProvider).blurEffectsEnabled;
    final bool simplifiedBackground = performanceMode || !blurEnabled;

    return Stack(
      children: [
        // 1. Deep Space Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF020005), // Deepest Black/Purple
                Color(0xFF050810), // Dark Blue
                Color(0xFF0B0D15), // Slightly lighter
                Color(0xFF020005),
              ],
            ),
          ),
        ),

        // 2. Real Star Field (Procedural replacement for asset)
        const Positioned.fill(child: _ProceduralStarField()),

        // 3. Infinite RGB comet scattering illusion - Only if not simplified
        if (!simplifiedBackground)
          const Positioned.fill(child: _CometScattering()),

        // 4. Content
        widget.child,
      ],
    );
  }
}

// =====================
// 2. REAL STAR FIELD (Procedural)
// =====================
class _ProceduralStarField extends StatelessWidget {
  const _ProceduralStarField();

  @override
  Widget build(BuildContext context) {
    // Uses CustomPaint to simulate a static, deep star texture
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(seconds: 12),
        opacity: 0.65,
        child: CustomPaint(size: Size.infinite, painter: _StarFieldPainter()),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  // Static seed for consistent look
  final Random _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    // Draw 100 subtle deep stars (Optimized from 300)
    for (int i = 0; i < 100; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      // Vary opacity for depth
      paint.color = Colors.white.withOpacity(_random.nextDouble() * 0.4 + 0.1);

      // Vary size
      final s = _random.nextDouble() * 1.5;

      canvas.drawCircle(Offset(x, y), s, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =====================
// 3. COMET SCATTERING PHYSICS
// =====================
class _CometScattering extends StatefulWidget {
  const _CometScattering();

  @override
  State<_CometScattering> createState() => _CometScatteringState();
}

class _CometScatteringState extends State<_CometScattering>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = controller.value;
          return CustomPaint(painter: _CometPainter(progress: t));
        },
      ),
    );
  }
}

// =====================
// COMET PAINTER (CORE)
// =====================
class _CometPainter extends CustomPainter {
  final double progress;

  _CometPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Only draw one smooth comet cycle
    final start = Offset(
      lerpDouble(-0.2 * size.width, size.width * 1.2, progress)!,
      size.height * 0.25,
    );

    final end = Offset(start.dx - 260, start.dy + 60);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.redAccent.withOpacity(0.25),
          Colors.greenAccent.withOpacity(0.25),
          Colors.blueAccent.withOpacity(0.25),
          Colors.purpleAccent.withOpacity(0.35),
          Colors.white.withOpacity(0.6),
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
