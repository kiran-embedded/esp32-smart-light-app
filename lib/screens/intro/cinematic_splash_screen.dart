import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class CinematicSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const CinematicSplashScreen({super.key, required this.onFinished});

  @override
  State<CinematicSplashScreen> createState() => _CinematicSplashScreenState();
}

class _CinematicSplashScreenState extends State<CinematicSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;

  // Scoped animations
  late Animation<double> _nebulaOpacity;
  late Animation<double> _energyCoreScale;
  late Animation<double> _energyCoreOpacity;
  late Animation<double> _logoReveal;
  late Animation<double> _textReveal;
  late Animation<double> _bootIndicator;
  late Animation<double> _transitionOut;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: 4500.ms);

    // Timing Setup
    _nebulaOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeIn),
    );

    _energyCoreOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.12, 0.3, curve: Curves.easeInOut),
    );

    _energyCoreScale = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.12, 0.4, curve: Curves.easeOutBack),
    );

    _logoReveal = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.5, curve: Curves.easeOutCubic),
    );

    _textReveal = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.45, 0.65, curve: Curves.easeOut),
    );

    _bootIndicator = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 0.8, curve: Curves.easeInOut),
    );

    _transitionOut = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.85, 1.0, curve: Curves.fastOutSlowIn),
    );

    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (reducedMotion) {
      _mainController.duration = 1.seconds;
    }
    _mainController.forward().then((_) {
      if (mounted) widget.onFinished();
    });

    // Suble haptic at boot pulse
    Future.delayed(1200.ms, () {
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Scene 1: Nebula & Stars
              Opacity(
                opacity: _nebulaOpacity.value * (1.0 - _transitionOut.value),
                child: CustomPaint(
                  painter: _NebulaPainter(
                    time: _mainController.value,
                    energyAmount: _energyCoreOpacity.value,
                  ),
                ),
              ),

              // Scene 2: Energy Core
              Center(
                child: Opacity(
                  opacity: _energyCoreOpacity.value * (1.0 - _logoReveal.value),
                  child: Transform.scale(
                    scale: 0.5 + (_energyCoreScale.value * 1.5),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyan.withOpacity(0.35),
                            Colors.deepPurpleAccent.withOpacity(0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Scene 3: Logo Reveal
              Center(
                child: Opacity(
                  opacity: _logoReveal.value * (1.0 - _transitionOut.value),
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * _logoReveal.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogoShards(),
                        const SizedBox(height: 30),

                        // Scene 4: Typography
                        Opacity(
                          opacity: _textReveal.value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - _textReveal.value)),
                            child: Column(
                              children: [
                                // Scene 4: Typography with RGB Infinity Sweep
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    final sweepProgress = _textReveal.value;
                                    return LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: const [
                                        Colors.red,
                                        Colors.orange,
                                        Colors.yellow,
                                        Colors.green,
                                        Colors.cyan,
                                        Colors.blue,
                                        Colors.purple,
                                        Colors.red,
                                      ],
                                      stops: [
                                        0.0,
                                        0.15,
                                        0.3,
                                        0.45,
                                        0.6,
                                        0.75,
                                        0.9,
                                        1.0,
                                      ],
                                      transform: GradientRotation(
                                        sweepProgress * 2 * math.pi,
                                      ),
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'NEBULA CORE',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'INTELLIGENT CONTROL PLATFORM',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Scene 5: Boot Indicator (Scanline)
              if (_bootIndicator.value > 0 && _bootIndicator.value < 1)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.5,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: math.sin(_bootIndicator.value * math.pi),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.cyanAccent,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoShards() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scene 3: Shard Assembly
          if (_logoReveal.value < 0.9)
            CustomPaint(
              size: const Size(150, 150),
              painter: _ShardPainter(progress: _logoReveal.value),
            ),

          // Final Logo with Chromatic Dispersion
          Opacity(
            opacity: _logoReveal.value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * _logoReveal.value),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3 * _logoReveal.value),
                      blurRadius: 30,
                      offset: const Offset(-3, 0),
                    ),
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(
                        0.3 * _logoReveal.value,
                      ),
                      blurRadius: 30,
                      offset: const Offset(3, 0),
                    ),
                    // Adding a central "White Core" glow
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2 * _logoReveal.value),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShardPainter extends CustomPainter {
  final double progress;
  _ShardPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.9) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 * (1 - progress))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final count = 40;

    for (int i = 0; i < count; i++) {
      final random = math.Random(i);
      final angle = random.nextDouble() * 2 * math.pi;
      // Shards start far and move to center
      final distance = 100 * (1 - progress) * (0.5 + random.nextDouble());
      final offset = Offset(
        center.dx + distance * math.cos(angle),
        center.dy + distance * math.sin(angle),
      );

      final shardSize = 2.0 + (3.0 * random.nextDouble());
      canvas.drawRect(
        Rect.fromCenter(center: offset, width: shardSize, height: shardSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShardPainter oldDelegate) => true;
}

class _NebulaPainter extends CustomPainter {
  final double time;
  final double energyAmount;
  final math.Random random = math.Random(42);

  _NebulaPainter({required this.time, required this.energyAmount});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Static Starfield (Noise)
    final starPaint = Paint()..color = Colors.white.withOpacity(0.15);
    for (int i = 0; i < 150; i++) {
      final x = math.Random(i).nextDouble() * size.width;
      final y = math.Random(i + 1000).nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, starPaint);
    }

    // 2. Animated Nebula Dust
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 5; i++) {
      final nebulaPaint = Paint()
        ..color = (i % 2 == 0 ? Colors.indigo : Colors.deepPurple).withOpacity(
          0.02 + (0.01 * math.sin(time * 2 + i)),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

      final offset = Offset(
        center.dx + 50 * math.cos(time * 0.5 + i),
        center.dy + 50 * math.sin(time * 0.5 + i),
      );
      canvas.drawCircle(offset, 150.0 + (20.0 * i), nebulaPaint);
    }

    // 3. star drift
    final driftPaint = Paint()..color = Colors.white.withOpacity(0.3);
    for (int i = 0; i < 30; i++) {
      final seed = i * 777;
      final speed = 0.05 + (0.1 * math.Random(seed).nextDouble());
      final x =
          (math.Random(seed).nextDouble() * size.width + (time * 20 * speed)) %
          size.width;
      final y = math.Random(seed + 1).nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.8, driftPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) => true;
}
