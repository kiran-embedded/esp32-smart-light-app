import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/gestures.dart';

/// WRAPPER FOR INTENT PREDICTION ANIMATION (IPA)
///
/// "UI moves before the user finishes the gesture."
/// - Reacts on PointerDown (Intent) rather than TapUp.
/// - Sharpen effect: Contrast ↑, Blur ↓
/// - Pin-Point Focus: Stable target, dimmed surroundings (simulated via contrast).
class IntentPredictionWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isToggled; // For state-aware animations
  final double scaleFactor;

  const IntentPredictionWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.isToggled = false,
    this.scaleFactor = 0.98,
  });

  @override
  State<IntentPredictionWrapper> createState() =>
      _IntentPredictionWrapperState();
}

class _IntentPredictionWrapperState extends State<IntentPredictionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sharpnessAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80), // Ultra-fast reaction
      reverseDuration: const Duration(milliseconds: 200), // Smooth release
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    _sharpnessAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
    // "On tap: No scale animation. Instead -> the world resolves into the destination"
    // We reverse slowly to simulate "resolving".
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Sharpness effect: Increase contrast slightly on press
          final double contrast = 1.0 + (_sharpnessAnimation.value * 0.1);

          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(<double>[
                contrast,
                0,
                0,
                0,
                0,
                0,
                contrast,
                0,
                0,
                0,
                0,
                0,
                contrast,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
