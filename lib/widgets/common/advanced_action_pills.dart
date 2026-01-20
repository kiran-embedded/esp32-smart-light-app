import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/display_settings_provider.dart';
import '../../providers/performance_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/ui/responsive_layout.dart';
import '../common/pixel_led_border.dart';
import '../scheduler/scheduler_settings_popup.dart';
import '../ai/ai_assistant_dialog.dart';
import '../common/frosted_glass.dart';
import '../../providers/google_home_provider.dart';

/// Super Action Pill - Consolidated iOS-style control center
class SuperActionPill extends ConsumerWidget {
  const SuperActionPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(displaySettingsProvider);
    final scale = displaySettings.displayScale;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding * scale,
      ),
      child: Container(
        padding: EdgeInsets.all(24 * scale),
        decoration: BoxDecoration(
          color:
              Colors.transparent, // Background now handled by inner blur/items
          borderRadius: BorderRadius.circular(40 * scale),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40 * scale),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: const _SuperSegmentQuickToggle()),
                    SizedBox(width: 16 * scale),
                    Expanded(child: const _SuperSegmentEnergy()),
                  ],
                ),
                SizedBox(height: 16 * scale),
                Row(
                  children: [
                    Expanded(child: const _SuperSegmentGoogleHome()),
                    SizedBox(width: 16 * scale),
                    Expanded(child: const _SuperSegmentVoice()),
                  ],
                ),
                SizedBox(height: 16 * scale),
                const _SuperSegmentSchedule(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuperSegmentQuickToggle extends ConsumerWidget {
  const _SuperSegmentQuickToggle();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switches = ref.watch(switchDevicesProvider);
    final allActive = switches.every((s) => s.isActive);

    return _SuperActionItem(
      icon: Icons.power_settings_new_rounded,
      label: 'Main Power',
      status: allActive ? 'ALL ON' : 'HYBRID',
      color: Colors.amberAccent,
      onTap: () {
        HapticService.medium();
        final service = ref.read(firebaseSwitchServiceProvider);
        final target = !allActive;
        for (var s in switches) service.sendCommand(s.id, target ? 0 : 1);
      },
    );
  }
}

class _SuperSegmentEnergy extends ConsumerWidget {
  const _SuperSegmentEnergy();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SuperActionItem(
      icon: Icons.bolt_rounded,
      label: 'Energy Usage',
      status: '1.2 kWh',
      color: Colors.greenAccent,
      onTap: () {}, // Handled by shared logic or dialog
    );
  }
}

class _SuperSegmentGoogleHome extends ConsumerWidget {
  const _SuperSegmentGoogleHome();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final googleHomeLinked =
        ref.watch(googleHomeLinkedProvider).valueOrNull ?? false;

    return _SuperActionItem(
      icon: Icons.home_rounded,
      label: 'Google Home',
      status: googleHomeLinked ? 'SYNCED' : 'OFFLINE',
      color: Colors.blueAccent,
      onTap: () {
        HapticService.medium();
        if (googleHomeLinked) {
          _showGoogleHomeDialog(context, ref);
        } else {
          ref.read(googleHomeServiceProvider).linkGoogleHome();
        }
      },
    );
  }

  void _showGoogleHomeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final service = ref.read(googleHomeServiceProvider);
          final theme = Theme.of(context);

          return Dialog(
            backgroundColor: Colors.transparent,
            child: FrostedGlass(
              padding: const EdgeInsets.all(24),
              radius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Google Home',
                    style: GoogleFonts.outfit(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Google Home is linked. Your devices are synced to the cloud.',
                    style: GoogleFonts.outfit(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await service.unlinkGoogleHome();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Unlink',
                          style: TextStyle(
                            color: Colors.redAccent.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SuperSegmentVoice extends ConsumerWidget {
  const _SuperSegmentVoice();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SuperActionItem(
      icon: Icons.auto_awesome,
      label: 'Nebula AI',
      status: 'Ready',
      color: Colors.deepPurpleAccent,
      onTap: () async {
        HapticService.selection();
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const AiAssistantDialog(),
        );
      },
    );
  }
}

class _SuperSegmentSchedule extends ConsumerWidget {
  const _SuperSegmentSchedule();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(switchScheduleProvider);
    final active = schedules.where((s) => s.isEnabled).length;
    final scale = ref.watch(displaySettingsProvider).displayScale;

    return PixelLedBorder(
      borderRadius: 24,
      strokeWidth: 1.2,
      colors: [
        Colors.blueAccent,
        Colors.blueAccent.withOpacity(0.5),
        Colors.white.withOpacity(0.2),
        Colors.blueAccent,
      ],
      duration: const Duration(seconds: 4),
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const SchedulerSettingsPopup(),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 20 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24 * scale),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.blueAccent,
                size: 20 * scale,
              ),
              SizedBox(width: 12 * scale),
              Text(
                'System Schedules',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp * scale,
                ),
              ),
              const Spacer(),
              Text(
                '$active Active',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp * scale,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 18 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _SuperActionItem({
    required this.icon,
    required this.label,
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PixelLedBorder(
      borderRadius: 24,
      strokeWidth: 1.2,
      colors: [
        color,
        color.withOpacity(0.5),
        Colors.white.withOpacity(0.2),
        color,
      ],
      duration: const Duration(seconds: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black, // Dark solid background for the "pill"
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                ),
              ),
              Text(
                status,
                style: GoogleFonts.outfit(
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Advanced Pills Row - Grid for actions with perfect alignment
class AdvancedPillsGrid extends ConsumerWidget {
  const AdvancedPillsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SuperActionPill();
  }
}

/// Exported Base Advanced Pill Widget for shared design
class AdvancedPillBase extends ConsumerStatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? child;

  const AdvancedPillBase({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.child,
  });

  @override
  ConsumerState<AdvancedPillBase> createState() => _AdvancedPillBaseState();
}

class _AdvancedPillBaseState extends ConsumerState<AdvancedPillBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySettings = ref.watch(displaySettingsProvider);
    final performanceMode = ref.watch(performanceProvider);
    final scale = displaySettings.displayScale;
    final fontSizeMultiplier = displaySettings.fontSizeMultiplier;

    final themePrimary = theme.colorScheme.primary;
    final blendedColor =
        Color.lerp(widget.color, themePrimary, 0.4) ?? widget.color;

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
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breathingController, _glowController]),
          builder: (context, child) {
            final breathingScale = 1.0 + (_breathingController.value * 0.015);
            final glowIntensity = 0.5 + (_glowController.value * 0.5);

            return Transform.scale(
              scale: performanceMode ? 1.0 : breathingScale,
              child: Container(
                padding: EdgeInsets.all(20 * scale),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      blendedColor.withOpacity(0.2 * glowIntensity),
                      blendedColor.withOpacity(0.05),
                      theme.scaffoldBackgroundColor.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32 * scale),
                  border: Border.all(
                    color: blendedColor.withOpacity(0.35 * glowIntensity),
                    width: 1.2,
                  ),
                  boxShadow: performanceMode
                      ? []
                      : [
                          BoxShadow(
                            color: blendedColor.withOpacity(
                              0.15 * glowIntensity,
                            ),
                            blurRadius: 30,
                            spreadRadius: -10,
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32 * scale),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [blendedColor, Colors.white],
                              ).createShader(bounds),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 24 * scale,
                              ),
                            ),
                            const Spacer(),
                            Container(
                                  width: 8 * scale,
                                  height: 8 * scale,
                                  decoration: BoxDecoration(
                                    color: blendedColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: blendedColor.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  duration: 1.seconds,
                                  curve: Curves.easeInOut,
                                ),
                          ],
                        ),
                        if (widget.child != null) ...[
                          Expanded(child: widget.child!),
                        ] else ...[
                          const Spacer(),
                        ],
                        SizedBox(height: 12.h * scale),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: GoogleFonts.outfit(
                                  fontSize:
                                      (14 * fontSizeMultiplier * scale).sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.subtitle,
                                style: GoogleFonts.outfit(
                                  fontSize:
                                      (10 * fontSizeMultiplier * scale).sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
