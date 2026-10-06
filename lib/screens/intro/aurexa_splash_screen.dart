import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AurexaSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const AurexaSplashScreen({super.key, required this.onFinished});

  @override
  State<AurexaSplashScreen> createState() => _AurexaSplashScreenState();
}

class _AurexaSplashScreenState extends State<AurexaSplashScreen> {
  @override
  void initState() {
    super.initState();
    // System UI styling for the splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Wait for the animation + splash duration, then transition
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Image with fast zoom
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
          ).animate()
           .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 1500.ms, curve: Curves.easeOutCubic),
          
          // Bottom Loading Indicator (Green)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)), // Emerald Green
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
