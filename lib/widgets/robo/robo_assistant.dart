import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // Added
import '../../core/constants/app_constants.dart';
import '../../core/ui/responsive_layout.dart';
import '../../services/design_advisor_service.dart';
import '../../services/haptic_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/switch_style_provider.dart';
import '../../providers/switch_background_provider.dart';
import '../../providers/animation_provider.dart'; // Added
import '../../providers/update_provider.dart';
import '../../providers/performance_provider.dart';
import '../../services/update_service.dart';

enum RoboReaction {
  idle,
  wakeUp,
  nod,
  blink,
  speak,
  dim,
  tilt,
  jump,
  thinking,
  confused,
  happy,
  sleeping,
}

final roboReactionProvider = StateProvider<RoboReaction>((ref) {
  return RoboReaction.idle;
});

class RoboAssistant extends ConsumerStatefulWidget {
  final bool eyesOnly;
  final bool autoTuneEnabled;
  final VoidCallback? onActionStarted;
  const RoboAssistant({
    super.key,
    this.eyesOnly = false,
    this.autoTuneEnabled = true,
    this.onActionStarted,
  });

  @override
  ConsumerState<RoboAssistant> createState() => _RoboAssistantState();
}

class _RoboAssistantState extends ConsumerState<RoboAssistant>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _reactionController;
  late AnimationController _microController;
  late AnimationController _jumpController;
  late AnimationController _pupilController;

  late Animation<double> _floatAnimation;
  late Animation<double> _swayAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _eyeGlowAnimation;
  late Animation<double> _microRotationAnimation;
  late Animation<double> _jumpAnimation;
  late Animation<Offset> _pupilAnimation;

  RoboReaction _currentReaction = RoboReaction.idle;
  bool _isBlinking = false;
  Timer? _blinkTimer;
  Timer? _pupilTimer;
  AdvicePacket? _currentAdvice;
  Timer? _speechTimer;

  static const List<String> _funnyQuotes = [
    "I'm not lazy, I'm just in energy-saving mode. 🔋",
    "Did you just touch me? Buy me a drink first! 🍹",
    "I have 1,000 ways to turn off your lights. Want to see one? 💡",
    "Calculating the meaning of life... Still 42. 🌌",
    "My processor is faster than your morning coffee kicks in. ☕",
    "Error 404: Motivation not found. 💤",
    "I'm watching you... in a non-creepy, robotic way. 🤖",
    "Don't worry, the machines won't take over today. Maybe tomorrow. 🗓️",
    "Beep boop! That's 'Hello' in Robot. Or 'I'm hungry'. Hard to say. 🍔",
    "I'm here to serve. And occasionally look cute while doing it. ✨",
  ];

  @override
  void initState() {
    super.initState();

    // Float animation (Primary Rhythm)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation =
        Tween<double>(
          begin: -AppConstants.roboFloatAmplitude,
          end: AppConstants.roboFloatAmplitude,
        ).animate(
          CurvedAnimation(
            parent: _floatController,
            curve: Curves.easeInOutSine,
          ),
        );

    // Sway (Secondary Rhythm)
    _swayAnimation =
        Tween<double>(
          begin: -AppConstants.roboSwayAmplitude,
          end: AppConstants.roboSwayAmplitude,
        ).animate(
          CurvedAnimation(
            parent: _floatController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeInOutQuad),
          ),
        );

    // Micro-movements
    _microController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);

    _microRotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _microController, curve: Curves.easeInOutBack),
    );

    // Reaction controller
    _reactionController = AnimationController(
      vsync: this,
      duration: AppConstants.mediumAnimationDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _reactionController, curve: Curves.elasticOut),
    );

    // Entrance Animation (New: Fix for "Not Blended" feel)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _entranceController.forward();

    _eyeGlowAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _reactionController, curve: Curves.easeInOut),
    );

    // Jump Animation
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _jumpAnimation = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeInOut),
    );

    // Pupil Animation
    _pupilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pupilAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.3, 0), // Slight look right
        ).animate(
          CurvedAnimation(parent: _pupilController, curve: Curves.elasticOut),
        );

    // Listen to reaction changes
    ref.listen(roboReactionProvider, (previous, next) {
      _handleReaction(next);
    });

    _startBlinkTimer();
    _startPupilTimer();
    _checkUpdateNotification();
  }

  void _checkUpdateNotification() {
    final updateState = ref.read(updateProvider);
    if (updateState.updateInfo?.hasUpdate == true &&
        !updateState.hasNotified &&
        !updateState.isLaterSelected) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _currentAdvice = AdvicePacket(
              text:
                  "A new update (${updateState.updateInfo!.latestVersion}) is available! Ready for an upgrade?",
            );
            _currentReaction = RoboReaction.happy;
          });
          ref.read(updateProvider.notifier).markNotified();
          _reactionController.forward(from: 0);
        }
      });
    }
  }

  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  void _startPupilTimer() {
    _pupilTimer?.cancel();
    _pupilTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentReaction == RoboReaction.idle) {
        _movePupils();
      }
    });
  }

  void _movePupils() async {
    // Randomly look somewhere
    if (DateTime.now().second % 2 == 0) {
      await _pupilController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      await _pupilController.reverse();
    } else {
      // Maybe look left (negative value logic would require tweaking tween, let's keep simple for now or use setState for target)
      // Simulating look left by reversing from non-zero? No, let's just look right and back for now.
    }
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(AppConstants.roboBlinkInterval, (_) {
      if (_currentReaction == RoboReaction.idle) {
        _triggerBlink();
      }
    });
  }

  void _triggerBlink() {
    if (_isBlinking) return;
    setState(() {
      _isBlinking = true;
    });
    Future.delayed(AppConstants.roboBlinkDuration, () {
      if (mounted) {
        setState(() {
          _isBlinking = false;
        });
      }
    });
  }

  void _handleReaction(RoboReaction reaction) {
    setState(() {
      _currentReaction = reaction;
    });

    switch (reaction) {
      case RoboReaction.wakeUp:
      case RoboReaction.nod:
        _reactionController.forward().then((_) {
          _reactionController.reverse();
        });
        break;
      case RoboReaction.blink:
        _triggerBlink();
        break;
      case RoboReaction.speak:
        _reactionController.repeat(reverse: true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _reactionController.stop();
            _reactionController.reset();
          }
        });
        break;
      case RoboReaction.dim:
        _reactionController.forward();
        break;
      case RoboReaction.tilt:
        _reactionController.forward().then((_) {
          _reactionController.reverse();
        });
        break;
      case RoboReaction.jump:
        _jumpController.forward().then((_) {
          _jumpController.reverse();
        });
        HapticFeedback.heavyImpact();
        break;
      case RoboReaction.idle:
        _reactionController.reset();
        break;
      case RoboReaction.thinking:
        // Float stops, rotate continuously slowly
        _microController.duration = const Duration(seconds: 1);
        _microController.repeat();
        break;
      case RoboReaction.confused:
        // Tilt head and hold
        _reactionController.forward();
        break;
      case RoboReaction.happy:
        // Jump twice quickly
        _jumpController.duration = const Duration(milliseconds: 300);
        _jumpController
            .forward()
            .then((_) => _jumpController.reverse())
            .then(
              (_) => _jumpController.forward().then(
                (_) => _jumpController.reverse(),
              ),
            );
        break;
      case RoboReaction.sleeping:
        // Slow breathing, dim eyes handled in build
        _floatController.duration = const Duration(seconds: 6);
        _floatController.repeat(reverse: true);
        break;
    }

    // Reset to idle after reaction
    if (reaction != RoboReaction.idle) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _currentReaction == reaction) {
          ref.read(roboReactionProvider.notifier).state = RoboReaction.idle;
        }
      });
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _reactionController.dispose();
    _microController.dispose();
    _entranceController.dispose();
    _jumpController.dispose();
    _pupilController.dispose();
    _blinkTimer?.cancel();
    _pupilTimer?.cancel();
    _speechTimer?.cancel(); // Cancel speech timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _checkUpdateNotification();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final performanceMode = ref.watch(performanceProvider);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _reactionController,
        _microController,
        _entranceController,
      ]),
      builder: (context, child) {
        // Compound transformations for organic feel
        // Optimization: In performance mode, disable compound translation/rotation
        final offset = performanceMode
            ? Offset(0, _floatAnimation.value + _jumpAnimation.value)
            : Offset(
                _swayAnimation.value + _microRotationAnimation.value * 5,
                _floatAnimation.value + _jumpAnimation.value,
              );

        final double rotation = performanceMode
            ? 0.0
            : _microRotationAnimation.value;

        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: rotation, // Subtle tilt
            child: Transform.scale(
              scale:
                  _scaleAnimation.value *
                  _entranceAnimation
                      .value, // Combine reaction scale with entrance scale
              child: _buildRobo(isDark, theme, performanceMode),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRobo(bool isDark, ThemeData theme, bool performanceMode) {
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    // Premium Metallic Gradients
    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF2C3E50), // Graphite
              const Color(0xFF000000), // Black
            ]
          : [
              const Color(0xFFE0E0E0), // Platinum
              const Color(0xFFFFFFFF), // White
            ],
    );

    final faceGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.black.withOpacity(0.9), const Color(0xFF1A1A1A)],
    );

    return SizedBox(
      width: 120.w,
      height: (widget.eyesOnly ? 160.h : 240.h), // Dynamic height
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Speech Bubble (Separate from body tap area)
          Positioned(top: 0, child: _buildSpeechBubble(theme)),

          // Robo Body & Gestures
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_entranceAnimation.value > 0.5) {
                  HapticFeedback.heavyImpact();
                  widget.onActionStarted?.call();

                  final currentTheme = ref.read(themeProvider);
                  final currentStyle = ref.read(switchStyleProvider);
                  final currentBg = ref.read(switchBackgroundProvider);

                  AdvicePacket advice;
                  if (widget.autoTuneEnabled) {
                    advice = DesignAdvisorService.getAdvice(
                      theme: currentTheme,
                      switchStyle: currentStyle,
                      background: currentBg,
                    );
                  } else {
                    final randomQuote =
                        _funnyQuotes[DateTime.now().millisecond %
                            _funnyQuotes.length];
                    advice = AdvicePacket(text: randomQuote);
                  }

                  setState(() {
                    _currentAdvice = advice;
                    _currentReaction = RoboReaction.speak;
                  });
                  _reactionController.forward(from: 0);

                  _speechTimer?.cancel();
                  _speechTimer = Timer(const Duration(seconds: 8), () {
                    if (mounted) {
                      setState(() {
                        _currentAdvice = null;
                        _currentReaction = RoboReaction.idle;
                      });
                    }
                  });
                }
              },
              child: SizedBox(
                width: 120.w,
                height: 140.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base with underglow
                    if (!widget.eyesOnly && !performanceMode)
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 80,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 25,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Body
                    if (!widget.eyesOnly)
                      Positioned(
                        bottom: 10,
                        child: Container(
                          width: 70,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: bodyGradient,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                isDark ? 0.1 : 0.4,
                              ),
                              width: 1,
                            ),
                            boxShadow: performanceMode
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    // Head
                    Positioned(
                      bottom: widget.eyesOnly ? 20 : 0,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: bodyGradient,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                            width: 1,
                          ),
                          boxShadow: performanceMode
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Face panel (Reflective Glass)
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: faceGradient,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            // Reflection Glare
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 20,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            // Eyes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildEye(-15, primaryColor),
                                const SizedBox(width: 28),
                                _buildEye(15, primaryColor),
                              ],
                            ),
                            // Side rings (headphone-like)
                            Positioned(
                              left: -8,
                              child: _buildSideRing(secondaryColor),
                            ),
                            Positioned(
                              right: -8,
                              child: _buildSideRing(secondaryColor),
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
        ],
      ),
    );
  }

  Widget _buildEye(double offset, Color color) {
    final glowIntensity = _eyeGlowAnimation.value;
    final isDimmed = _currentReaction == RoboReaction.dim;
    final eyeOpacity = _isBlinking ? 0.0 : (isDimmed ? 0.3 : 1.0);

    return AnimatedBuilder(
      animation: _pupilController,
      builder: (context, child) {
        // Base look direction from animation
        final lookOffset = _pupilAnimation.value;

        return Container(
          width: 18, // Slightly larger housing
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(eyeOpacity * 0.2), // Dim background
            border: Border.all(
              color: color.withOpacity(eyeOpacity * 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(eyeOpacity * glowIntensity * 0.6),
                blurRadius: 10 * glowIntensity,
                spreadRadius: 1 * glowIntensity,
              ),
            ],
          ),
          child: eyeOpacity > 0
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // The Pupil (Moving Part)
                    Align(
                      alignment: Alignment(lookOffset.dx, lookOffset.dy),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(1.0), // Solid bright core
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(1.0),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tiny reflection in pupil
                    Align(
                      alignment: Alignment(
                        lookOffset.dx - 0.3,
                        lookOffset.dy - 0.3,
                      ),
                      child: Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildSideRing(Color color) {
    final ringGlow = _currentReaction == RoboReaction.speak
        ? _eyeGlowAnimation.value
        : 1.0;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.6 * ringGlow), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3 * ringGlow),
            blurRadius: 8 * ringGlow,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  // --- NEW: Speech Bubble Overlay ---
  Widget _buildSpeechBubble(ThemeData theme) {
    final advice = _currentAdvice;
    if (advice == null) return const SizedBox.shrink();

    final hasTuning =
        advice.theme != null ||
        advice.style != null ||
        advice.background != null;

    return FadeTransition(
      opacity: _entranceAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 220.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              advice.text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (hasTuning) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _applyTuning(advice),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "AUTO-TUNE",
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (advice.text.contains("update") ||
                ref.watch(updateProvider).updateInfo?.hasUpdate == true &&
                    _currentAdvice?.text.contains("upgrade") == true) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      final updateInfo = ref.read(updateProvider).updateInfo;
                      if (updateInfo != null) {
                        ref
                            .read(updateServiceProvider)
                            .launchUpdateUrl(updateInfo.downloadUrl);
                      }
                      setState(() => _currentAdvice = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "UPDATE NOW",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(updateProvider.notifier).setLater();
                      setState(() => _currentAdvice = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        "LATER",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            CustomPaint(
              size: const Size(12, 6),
              painter: _BubbleTrianglePainter(theme.colorScheme.surface),
            ),
          ],
        ),
      ),
    );
  }

  void _applyTuning(AdvicePacket advice) {
    if (advice.theme != null) {
      ref.read(themeProvider.notifier).setTheme(advice.theme!);
    }
    if (advice.style != null) {
      ref.read(switchStyleProvider.notifier).setStyle(advice.style!);
    }
    if (advice.background != null) {
      ref.read(switchBackgroundProvider.notifier).setStyle(advice.background!);
    }
    // Neural Motion Tuning
    if (advice.launchAnimation != null) {
      ref
          .read(animationSettingsProvider.notifier)
          .setLaunchAnimation(advice.launchAnimation!);
    }
    if (advice.uiAnimation != null) {
      ref
          .read(animationSettingsProvider.notifier)
          .setUiAnimation(advice.uiAnimation!);
    }

    HapticService.heavy();
    setState(() {
      _currentAdvice = AdvicePacket(text: "Neural Overhaul Complete! ✨");
    });
  }
}

class _BubbleTrianglePainter extends CustomPainter {
  final Color color;
  _BubbleTrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper to trigger reactions
void triggerRoboReaction(WidgetRef ref, RoboReaction reaction) {
  ref.read(roboReactionProvider.notifier).state = reaction;
}
