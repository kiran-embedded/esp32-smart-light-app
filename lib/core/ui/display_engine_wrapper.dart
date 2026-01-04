import 'dart:ui';
import 'package:flutter/material.dart';
import '../system/display_engine.dart';

/// A global wrapper that provides high-end visual polish and scaling context.
/// This imparts the "Unreal Engine" feel through subtle grain, vignetting, and smooth overlays.
class DisplayEngineWrapper extends StatelessWidget {
  final Widget child;

  const DisplayEngineWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Initialize standard Responsive as well for backward compatibility
    DisplayEngine.init(context);

    return Stack(
      children: [
        child,

        // 1. High-End Visual Polish: Subtle Vignette (Unreal Feel)
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Colors.transparent, Colors.black.withOpacity(0.08)],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // 2. Global Overlay for Color Grading (Subtle)
        IgnorePointer(
          child: Container(
            color: Colors.blueAccent.withOpacity(
              0.005,
            ), // Micro-tint for "Cold/Futuristic" feel
          ),
        ),

        // 3. Optional: Global Film Grain (Too heavy? We'll keep it very subtle)
        // Note: For real grain we'd use a shader, but a low-opacity noise texture works too.

        // 4. Calibration Feedback
        const _NadeCalibrationOverlay(),
      ],
    );
  }
}

class _NadeCalibrationOverlay extends StatefulWidget {
  const _NadeCalibrationOverlay();
  @override
  State<_NadeCalibrationOverlay> createState() =>
      _NadeCalibrationOverlayState();
}

class _NadeCalibrationOverlayState extends State<_NadeCalibrationOverlay> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "NADE ENGINE CALIBRATED",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized widget to handle "Pills" the Unreal way
class UnrealPill extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final double? width;
  final bool glow;

  const UnrealPill({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.width,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: DisplayEngine.pillHeight,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(DisplayEngine.pillRadius),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: (color ?? Theme.of(context).colorScheme.primary)
                        .withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
