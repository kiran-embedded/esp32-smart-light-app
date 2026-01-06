import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:ui';

class NebulaOrb extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final bool isSuccess;

  const NebulaOrb({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.isSuccess,
  });

  @override
  State<NebulaOrb> createState() => _NebulaOrbState();
}

class _NebulaOrbState extends State<NebulaOrb> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSuccess) {
      return const Icon(
        Icons.check_circle,
        color: Colors.greenAccent,
        size: 80,
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut).fadeIn();
    }

    final double size = widget.isListening ? 120 : 100;

    return RepaintBoundary(
      child:
          Stack(
            alignment: Alignment.center,
            children: [
              // Core Glow
              AnimatedBuilder(
                animation: Listenable.merge([
                  _rotationController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: size + (_pulseController.value * 20),
                      height: size + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.6),
                            Colors.purpleAccent.withOpacity(0.6),
                            Colors.blueAccent.withOpacity(0.6),
                            Colors.cyanAccent.withOpacity(0.6),
                          ],
                          stops: const [0.0, 0.33, 0.66, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            blurRadius: widget.isProcessing ? 50 : 30,
                            spreadRadius: widget.isProcessing ? 10 : 2,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                      ),
                    ),
                  );
                },
              ),

              // Inner detail (Nebula swirls)
              if (widget.isProcessing)
                SizedBox(
                  width: 60,
                  height: 60,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),

              // Icon Overlay (Mic)
              if (!widget.isProcessing && !widget.isSuccess)
                Icon(Icons.mic, color: Colors.white.withOpacity(0.9), size: 32)
                    .animate()
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.elasticOut,
                      duration: 500.ms,
                    )
                    .fadeIn(),
            ],
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            curve: Curves.easeOutBack,
            duration: 400.ms,
          ),
    );
  }
}
