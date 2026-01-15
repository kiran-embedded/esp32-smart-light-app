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
import '../../providers/performance_provider.dart';

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
  late AnimationController _entranceController;

  late Animation<double> _floatAnimation;
  late Animation<double> _swayAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _eyeGlowAnimation;
  late Animation<double> _microRotationAnimation;
  late Animation<double> _jumpAnimation;
  late Animation<Offset> _pupilAnimation;
  late Animation<double> _entranceAnimation;

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

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _swayAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutQuad),
      ),
    );

    _microController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);

    _microRotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _microController, curve: Curves.easeInOutBack),
    );

    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _reactionController, curve: Curves.elasticOut),
    );

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

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _jumpAnimation = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeInOut),
    );

    _pupilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pupilAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.3, 0)).animate(
          CurvedAnimation(parent: _pupilController, curve: Curves.elasticOut),
        );

    _startBlinkTimer();
    _startPupilTimer();
  }

  void _startPupilTimer() {
    _pupilTimer?.cancel();
    _pupilTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentReaction == RoboReaction.idle) {
        _movePupils();
      }
    });
  }

  void _movePupils() async {
    if (DateTime.now().second % 2 == 0) {
      await _pupilController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      await _pupilController.reverse();
    }
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_currentReaction == RoboReaction.idle) {
        _triggerBlink();
      }
    });
  }

  void _triggerBlink() {
    if (_isBlinking) return;
    setState(() => _isBlinking = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isBlinking = false);
    });
  }

  void _handleReaction(RoboReaction reaction) {
    setState(() => _currentReaction = reaction);
    switch (reaction) {
      case RoboReaction.wakeUp:
      case RoboReaction.nod:
        _reactionController.forward().then(
          (_) => _reactionController.reverse(),
        );
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
      case RoboReaction.jump:
        _jumpController.forward().then((_) => _jumpController.reverse());
        HapticFeedback.heavyImpact();
        break;
      default:
        _reactionController.reset();
    }
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
    _speechTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final performanceMode = ref.watch(performanceProvider);

    ref.listen(roboReactionProvider, (previous, next) {
      _handleReaction(next);
    });

    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _reactionController,
        _microController,
        _entranceController,
      ]),
      builder: (context, child) {
        final offset = performanceMode
            ? Offset(0, _floatAnimation.value + _jumpAnimation.value)
            : Offset(
                _swayAnimation.value + _microRotationAnimation.value * 5,
                _floatAnimation.value + _jumpAnimation.value,
              );

        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: performanceMode ? 0.0 : _microRotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value * _entranceAnimation.value,
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

    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF2C3E50), const Color(0xFF000000)]
          : [const Color(0xFFE0E0E0), const Color(0xFFFFFFFF)],
    );

    final faceGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.black.withOpacity(0.9), const Color(0xFF1A1A1A)],
    );

    return SizedBox(
      width: 120.w,
      height: (widget.eyesOnly ? 160.h : 240.h),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, child: _buildSpeechBubble(theme)),
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
                          ),
                        ),
                      ),
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
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: faceGradient,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildEye(-15, primaryColor),
                                const SizedBox(width: 28),
                                _buildEye(15, primaryColor),
                              ],
                            ),
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
    final eyeOpacity = _isBlinking
        ? 0.0
        : (_currentReaction == RoboReaction.dim ? 0.3 : 1.0);

    return AnimatedBuilder(
      animation: _pupilController,
      builder: (context, child) {
        final lookOffset = _pupilAnimation.value;
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(eyeOpacity * 0.2),
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
                    Align(
                      alignment: Alignment(lookOffset.dx, lookOffset.dy),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
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

  Widget _buildSpeechBubble(ThemeData theme) {
    final advice = _currentAdvice;
    if (advice == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _entranceAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 220),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
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

void triggerRoboReaction(WidgetRef ref, RoboReaction reaction) {
  ref.read(roboReactionProvider.notifier).state = reaction;
}
