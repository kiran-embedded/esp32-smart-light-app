import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  int _messageIndex = 0;

  final List<String> messages = [
    'Initializing AUREXA...',
    'Connecting to your home...',
    'Syncing devices...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _textController.reverse();
            }
          });
        } else if (status == AnimationStatus.dismissed) {
          if (mounted) {
            setState(() {
              _messageIndex = (_messageIndex + 1) % messages.length;
            });
            _textController.forward();
          }
        }
      });

    _textController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Wave
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/aurexa_top_wave.png',
              fit: BoxFit.cover,
            ),
          ),
          // Bottom Wave
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/aurexa_bottom_wave.png',
              fit: BoxFit.cover,
            ),
          ),
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80), // Offset slightly
                // Logo Image with text
                Image.asset(
                  'assets/images/aurexa_logo_full.png',
                  width: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 50),
                
                // Aurexa Loader
                const AurexaLoader(),
                const SizedBox(height: 24),
                
                // Animated Loading Text
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textController.value,
                      child: Text(
                        messages[_messageIndex],
                        style: GoogleFonts.outfit(
                          color: Colors.black54,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AurexaLoader extends StatefulWidget {
  const AurexaLoader({super.key});

  @override
  State<AurexaLoader> createState() => _AurexaLoaderState();
}

class _AurexaLoaderState extends State<AurexaLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  
  // Phase shifts for left-to-right traveling wave
  final List<double> phaseShifts = [0.0, 0.4, 0.8, 1.2, 1.6];

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _bar(12 + sin(controller.value * pi * 2 - phaseShifts[0]) * 8),
            const SizedBox(width: 10),
            _bar(28 + sin(controller.value * pi * 2 - phaseShifts[1]) * 14),
            const SizedBox(width: 10),
            _bar(46 + sin(controller.value * pi * 2 - phaseShifts[2]) * 18),
            const SizedBox(width: 10),
            _bar(28 + sin(controller.value * pi * 2 - phaseShifts[3]) * 14),
            const SizedBox(width: 10),
            _bar(12 + sin(controller.value * pi * 2 - phaseShifts[4]) * 8),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    // Ensure height doesn't go below minimum
    final safeHeight = height < 4.0 ? 4.0 : height;
    
    return Container(
      width: 7,
      height: safeHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF69F0AE),
            Color(0xFF00D084),
          ],
        ),
      ),
    );
  }
}
