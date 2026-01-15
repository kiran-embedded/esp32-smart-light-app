import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/display_settings_provider.dart';
import '../../providers/performance_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/ui/responsive_layout.dart';

class PremiumActionPill extends ConsumerStatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final String? subtitle;

  const PremiumActionPill({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.subtitle,
  });

  @override
  ConsumerState<PremiumActionPill> createState() => _PremiumActionPillState();
}

class _PremiumActionPillState extends ConsumerState<PremiumActionPill>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySettings = ref.watch(displaySettingsProvider);
    final performanceMode = ref.watch(performanceProvider);
    final fontSizeMultiplier = displaySettings.fontSizeMultiplier;
    final displayScale = displaySettings.displayScale;

    return GestureDetector(
      onTapDown: (_) {
        HapticService.light();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w * displayScale,
            vertical: 18.h * displayScale,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isActive
                  ? [
                      widget.activeColor.withOpacity(0.2),
                      widget.activeColor.withOpacity(0.1),
                    ]
                  : [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(28.r * displayScale),
            border: Border.all(
              color: widget.isActive
                  ? widget.activeColor.withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (widget.isActive && !performanceMode)
                BoxShadow(
                  color: widget.activeColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Animated background glow
              if (widget.isActive && !performanceMode)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.r * displayScale),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: [
                              widget.activeColor.withOpacity(
                                0.1 + (_pulseController.value * 0.1),
                              ),
                              widget.activeColor.withOpacity(0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with glow
                  Container(
                    padding: EdgeInsets.all(12 * displayScale),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? widget.activeColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      boxShadow: widget.isActive && !performanceMode
                          ? [
                              BoxShadow(
                                color: widget.activeColor.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isActive
                          ? widget.activeColor
                          : Colors.white.withOpacity(0.6),
                      size: 28 * displayScale,
                    ),
                  )
                      .animate(
                        onPlay: (c) {
                          if (widget.isActive && !performanceMode) {
                            c.repeat(reverse: true);
                          }
                        },
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 2.seconds,
                        curve: Curves.easeInOut,
                      ),

                  SizedBox(height: 12.h * displayScale),

                  // Label
                  Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      fontSize: (14 * fontSizeMultiplier * displayScale).sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: widget.isActive
                          ? widget.activeColor
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),

                  // Subtitle
                  if (widget.subtitle != null) ...[
                    SizedBox(height: 4.h * displayScale),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.outfit(
                        fontSize: (10 * fontSizeMultiplier * displayScale).sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


