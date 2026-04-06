import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/haptic_service.dart';
import 'dart:ui';

class HelpBotOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const HelpBotOverlay({super.key, required this.onComplete});

  @override
  State<HelpBotOverlay> createState() => _HelpBotOverlayState();
}

class _HelpBotOverlayState extends State<HelpBotOverlay> {
  int _currentStep = 0;
  bool _isVisible = true;

  final List<HelpStep> _steps = [
    HelpStep(
      title: "I am Nebula AI",
      message:
          "Welcome to your high-performance smart hardware ecosystem. Let's optimize your experience.",
      icon: Icons.auto_awesome,
    ),
    HelpStep(
      title: "Instant Toggles",
      message:
          "Tap any tile for 0ms relay execution. Our dual-core engine ensures zero network lag.",
      icon: Icons.bolt,
    ),
    HelpStep(
      title: "Hidden Options",
      message:
          "Long-press any switch tile to access the Automation Engine, Inverted Logic, and Timers.",
      icon: Icons.settings_suggest,
    ),
    HelpStep(
      title: "Silent Zones",
      message:
          "In the Security Hub, long-press any sensor card to silence specific zones and prevent alarms.",
      icon: Icons.notifications_paused_rounded,
    ),
    HelpStep(
      title: "Tactile Interface",
      message:
          "Feel variable-intensity haptics as you slide LDR thresholds. The UI is alive.",
      icon: Icons.vibration,
    ),
  ];

  void _nextStep() {
    HapticService.selection();
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      setState(() => _isVisible = false);
      Future.delayed(400.ms, widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final step = _steps[_currentStep];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent backdrop
          GestureDetector(
            onTap: _nextStep,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ).animate().fadeIn(duration: 400.ms),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child:
                Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Bot Icon
                          Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  step.icon,
                                  color: Colors.cyanAccent,
                                  size: 30,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .shimmer(
                                duration: 2.seconds,
                                color: Colors.white24,
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                curve: Curves.easeInOut,
                              ),

                          const SizedBox(height: 20),

                          Text(
                                step.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              )
                              .animate(key: ValueKey('title_$_currentStep'))
                              .fadeIn()
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 12),

                          Text(
                                step.message,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              )
                              .animate(key: ValueKey('msg_$_currentStep'))
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 24),

                          // Progress and Next
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(_steps.length, (index) {
                                  return Container(
                                    width: index == _currentStep ? 20 : 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: index == _currentStep
                                          ? Colors.cyanAccent
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ).animate().scale(duration: 300.ms);
                                }),
                              ),
                              ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent
                                      .withOpacity(0.1),
                                  foregroundColor: Colors.cyanAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Colors.cyanAccent,
                                      width: 1,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _currentStep == _steps.length - 1
                                      ? "GOT IT"
                                      : "NEXT",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      curve: Curves.easeOutBack,
                      duration: 600.ms,
                    )
                    .fadeIn(),
          ),
        ],
      ),
    );
  }
}

class HelpStep {
  final String title;
  final String message;
  final IconData icon;

  HelpStep({required this.title, required this.message, required this.icon});
}
