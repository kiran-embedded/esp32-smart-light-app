import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'neural_mapping_view.dart';
import '../../widgets/security/calibration_hub_overlay.dart';
import '../../core/system/display_engine.dart' hide DisplayEngineExtension;
import '../../core/ui/responsive_layout.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../providers/security_provider.dart';
import '../../services/haptic_service.dart';
import '../../widgets/common/pixel_led_border.dart';
import 'dart:ui';

class SecurityView extends ConsumerStatefulWidget {
  const SecurityView({super.key});

  @override
  ConsumerState<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends ConsumerState<SecurityView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityState = ref.watch(securityProvider);
    final securityNotifier = ref.read(securityProvider.notifier);

    return Stack(
      children: [
        // Background Alarm Glow
        if (securityState.isAlarmActive)
          Positioned.fill(
            child: Container(
              color: Colors.red.withOpacity(0.12),
            ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 1200.ms),
          ),

        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // HEADING SPACE
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),

            // 1. MASTER CONTROL SECTION (TOP)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child:
                    _buildMasterControl(
                          context,
                          securityState,
                          securityNotifier,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.95, 0.95)),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // 1.5 GLOBAL MOTION PROTOCOL MASTER
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child:
                    _buildGlobalMotionMaster(
                          context,
                          securityState,
                          securityNotifier,
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 600.ms)
                        .slideY(begin: 0.1, end: 0),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // 2. SYSTEM VITALITY DASHBOARD (High Priority Telemetry)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildVitalityCard(context, securityState)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideX(begin: 0.1, end: 0),
              ),
            ),

            // 🚀 QUANTUM CALIBRATION HUB LAUNCHER (Premium Pill)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {
                    HapticService.heavy();
                    CalibrationHubOverlay.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: Colors.orangeAccent,
                            size: 20.sp,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CALIBRATION HUB",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                "Advanced Diagnostic Console v1.9.7",
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white24,
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // 3. CORE SECURITY CONTROLS & SCHEDULE
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildActivePeriods(context, securityState, ref),
                    const SizedBox(height: 20),
                    _buildMasterLDR(context, securityState, ref),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLocalSirenToggle(
                            context,
                            securityState,
                            securityNotifier,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBuzzerTest(context, securityNotifier),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildNeuralMappingButton(context, theme),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 32.h)),

            // 4. SENSOR GRID HEADER
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildGridHeader(securityState),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // 5. SENSOR GRID
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: securityState.sensors.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final name = securityState.sensors.keys.elementAt(
                          index,
                        );
                        final sensor = securityState.sensors[name]!;
                        return _SensorCard(
                              name: name,
                              sensor: sensor,
                              onAcknowledge: () =>
                                  securityNotifier.acknowledge(name),
                              onRename: (newName) =>
                                  securityNotifier.renameSensor(name, newName),
                            )
                            .animate()
                            .fadeIn(delay: (index * 50).ms)
                            .scale(begin: const Offset(0.9, 0.9));
                      }, childCount: securityState.sensors.length),
                    ),
            ),

            // 6. EMERGENCY PANIC
            SliverToBoxAdapter(child: SizedBox(height: 32.h)),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildSOSSlider(context, securityNotifier),
              ),
            ),

            // FOOTER SPACE
            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
          ],
        ),

        // ALARM OVERLAY (MODAL) - Gated by Native Alarm toggle
        if (securityState.isAlarmActive && securityState.isNativeAlarmEnabled)
          _buildAlarmOverlay(context, securityNotifier),

        // FIXED TOP BAR
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PremiumAppBar(
            title: Text(
              'SECURITY HUB',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.w,
                color: securityState.isAlarmActive
                    ? Colors.redAccent
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndustrialContainer({
    required Widget child,
    EdgeInsets? padding,
    bool isActive = false,
    Color? activeColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive
            ? (activeColor ?? Colors.cyanAccent).withOpacity(0.08)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive
              ? (activeColor ?? Colors.cyanAccent).withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildMasterLDR(
    BuildContext context,
    SecurityState state,
    WidgetRef ref,
  ) {
    return _buildIndustrialContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.light_mode_rounded,
                    color: Colors.amberAccent,
                    size: 16.sp,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "LIGHT SENSITIVITY",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white38,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.sync_rounded,
                color: Colors.amberAccent.withOpacity(0.5),
                size: 14.sp,
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${state.masterLightLevel}%",
                    style: GoogleFonts.outfit(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Ambient Light Node",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${state.ldrThreshold}%",
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.amberAccent,
                    ),
                  ),
                  Text(
                    "Trigger Threshold",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.amberAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.amberAccent,
              overlayColor: Colors.amberAccent.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: state.ldrThreshold.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (val) {
                HapticService.immersiveSliderFeedback(
                  val.toDouble(),
                  min: 0,
                  max: 100,
                );
                ref
                    .read(securityProvider.notifier)
                    .updateLdrThreshold(val.toInt());
              },
              onChangeEnd: (val) {
                HapticService.medium();
              },
            ),
          ),
          _buildIndustrialGatingToggle(
            context,
            state,
            ref.read(securityProvider.notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalSirenToggle(
    BuildContext context,
    SecurityState state,
    SecurityNotifier notifier,
  ) {
    final bool isEnabled = state.isNativeAlarmEnabled;
    return GestureDetector(
      onTap: () {
        HapticService.heavy();
        notifier.toggleNativeAlarm();
      },
      child: _buildIndustrialContainer(
        isActive: isEnabled,
        activeColor: Colors.redAccent,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: isEnabled ? Colors.redAccent : Colors.white38,
                  size: 18.sp,
                ),
                CupertinoSwitch(
                  value: isEnabled,
                  onChanged: (_) {
                    HapticService.heavy();
                    notifier.toggleNativeAlarm();
                  },
                  activeColor: Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "NATIVE SIREN",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: isEnabled ? Colors.redAccent : Colors.white70,
                letterSpacing: 1,
              ),
            ),
            Text(
              isEnabled ? "LOUD ACTIVE" : "QUIET MODE",
              style: GoogleFonts.outfit(fontSize: 8.sp, color: Colors.white38),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustrialGatingToggle(
    BuildContext context,
    SecurityState state,
    SecurityNotifier notifier,
  ) {
    final bool isGated = state.ldrSecurity;
    return GestureDetector(
      onTap: () {
        HapticService.heavy();
        notifier.toggleLdrSecurity();
      },
      child: _buildIndustrialContainer(
        isActive: isGated,
        activeColor: Colors.amberAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isGated ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: isGated ? Colors.amberAccent : Colors.white38,
                  size: 14.sp,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGated ? "AUTO DARKNESS GATED" : "ALWAYS ACTIVE (24/7)",
                      style: GoogleFonts.outfit(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        color: isGated ? Colors.amberAccent : Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      isGated
                          ? "Detects only in darkness"
                          : "Active day and night",
                      style: GoogleFonts.outfit(
                        fontSize: 8.sp,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            CupertinoSwitch(
              value: isGated,
              onChanged: (_) {
                HapticService.heavy();
                notifier.toggleLdrSecurity();
              },
              activeColor: Colors.amberAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuzzerTest(BuildContext context, SecurityNotifier notifier) {
    return GestureDetector(
      onTap: () {
        HapticService.heavy();
        notifier.testBuzzer();
      },
      child: _buildIndustrialContainer(
        isActive: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                      Icons.notification_important_rounded,
                      color: Colors.redAccent,
                      size: 18.sp,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 1.seconds, color: Colors.white24)
                    .shake(hz: 4, curve: Curves.easeInOut),
                Icon(
                  Icons.touch_app_rounded,
                  color: Colors.redAccent.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "PANIC BUZZER",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            Text(
              "HARDWARE TEST",
              style: GoogleFonts.outfit(fontSize: 8.sp, color: Colors.white38),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildNeuralMappingButton(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        HapticService.heavy();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NeuralMappingView()),
        );
      },
      child: _buildIndustrialContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hub_rounded,
                color: theme.colorScheme.primary,
                size: 18.sp,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "NEURAL MAPPING ENGINE",
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "Orchestrate complex node interactions",
                    style: GoogleFonts.outfit(
                      fontSize: 9.sp,
                      color: Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.primary.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildActivePeriods(
    BuildContext context,
    SecurityState state,
    WidgetRef ref,
  ) {
    return _buildIndustrialContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12.sp,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                "ACTIVE SCHEDULE",
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 24) / 3;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildSchedulePill(
                      'morning',
                      Icons.wb_twilight,
                      'MORNING',
                      state,
                      ref,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSchedulePill(
                      'afternoon',
                      Icons.wb_sunny,
                      'NOON',
                      state,
                      ref,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSchedulePill(
                      'evening',
                      Icons.nights_stay_outlined,
                      'EVENING',
                      state,
                      ref,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSchedulePill(
                      'night',
                      Icons.nightlight_round,
                      'NIGHT',
                      state,
                      ref,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSchedulePill(
                      'midnight',
                      Icons.star,
                      'MIDNIGHT',
                      state,
                      ref,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVitalityCard(BuildContext context, SecurityState state) {
    final bool isLdrOk = state.ldrValid;
    final int rssi = state.rssi;
    final bool isOnline = state.isHubOnline;

    Color getRssiColor(int val) {
      if (val > -65) return Colors.greenAccent;
      if (val > -85) return Colors.orangeAccent;
      return Colors.redAccent;
    }

    IconData getRssiIcon(int val) {
      if (val > -65) return Icons.wifi_rounded;
      if (val > -85) return Icons.wifi_2_bar_rounded;
      return Icons.wifi_1_bar_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.greenAccent : Colors.white24,
                          shape: BoxShape.circle,
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: 1.seconds,
                        begin: const Offset(1, 1),
                        end: Offset(1.3, 1.3),
                      )
                      .then()
                      .scale(duration: 1.seconds),
                  const SizedBox(width: 10),
                  Text(
                    "SYSTEM VITALITY",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white38,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Text(
                isOnline ? "HUB CONNECTED" : "HUB OFFLINE",
                style: GoogleFonts.outfit(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: isOnline ? Colors.greenAccent : Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildVitalTile(
                  context,
                  "WIFI SIGNAL",
                  "${rssi}dBm",
                  getRssiIcon(rssi),
                  getRssiColor(rssi),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalTile(
                  context,
                  "LDR OPTIC",
                  isLdrOk ? "NOMINAL" : "HARDWARE FAIL",
                  Icons.sensors_rounded,
                  isLdrOk ? Colors.cyanAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 7.sp,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePill(
    String key,
    IconData icon,
    String label,
    SecurityState state,
    WidgetRef ref,
  ) {
    final isActive = state.activePeriods[key] ?? true;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticService.heavy(); // Premium mechanical feel
        ref.read(securityProvider.notifier).setPeriodActive(key, !isActive);
      },
      child: AnimatedContainer(
        duration: 150.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? theme.colorScheme.primary : Colors.white24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : Colors.white24,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterControl(
    BuildContext context,
    SecurityState state,
    SecurityNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isArmed = state.isArmed;

    return PixelLedBorder(
      colors: isArmed
          ? [
              theme.colorScheme.primary,
              Colors.cyanAccent,
              theme.colorScheme.primary,
            ]
          : [Colors.white10, Colors.white24],
      borderRadius: 32,
      strokeWidth: isArmed ? 2.0 : 1.0,
      duration: const Duration(seconds: 3),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          boxShadow: isArmed
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: -10,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArmed ? "NEURAL GRID ACTIVE" : "GRID STANDBY",
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: isArmed
                            ? theme.colorScheme.primary
                            : Colors.white24,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      isArmed
                          ? "Protecting your ecosystem"
                          : "Manual override active",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isArmed ? Icons.shield_rounded : Icons.shield_outlined,
                  color: isArmed ? theme.colorScheme.primary : Colors.white10,
                  size: 32.sp,
                ),
              ],
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                HapticService.heavy();
                notifier.toggleArmed();
              },
              child: AnimatedContainer(
                duration: 80.ms,
                height: 56.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isArmed
                        ? [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ]
                        : [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isArmed
                        ? Colors.white10
                        : theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    isArmed ? "DISARM SECURITY HUB" : "ACTIVATE NEURAL GRID",
                    style: GoogleFonts.outfit(
                      color: isArmed ? Colors.white60 : Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeader(SecurityState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "SMART NODES",
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
        ),
        if (state.sensors.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${state.sensors.length} ONLINE",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                color: Colors.greenAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSOSSlider(BuildContext context, SecurityNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 72.h,
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              "SLIDE FOR EMERGENCY PANIC",
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent.withOpacity(0.3),
                letterSpacing: 1,
              ),
            ),
          ),
          Dismissible(
            key: const Key('sos_slider'),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) {
              HapticService.heavy();
              notifier.simulateTrigger("MANUAL_SOS", true);
            },
            child: Container(
              width: 56.h,
              height: 56.h,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [],
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          "SCANNING FOR ESP-NOW NODES...",
          style: GoogleFonts.outfit(
            color: Colors.white12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmOverlay(BuildContext context, SecurityNotifier notifier) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.red.withOpacity(0.4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: Colors.white,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: 80.ms,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                  ),
              const SizedBox(height: 24),
              Text(
                "ALARM ACTIVE",
                style: GoogleFonts.outfit(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "SECURITY BREACH DETECTED",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 64),
              GestureDetector(
                onTap: () {
                  HapticService.heavy();
                  notifier.stopAlarm();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "ACKNOWLEDGE & SILENCE",
                    style: GoogleFonts.outfit(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalMotionMaster(
    BuildContext context,
    SecurityState state,
    SecurityNotifier notifier,
  ) {
    final bool isNightOnly = state.globalMotionMode == 4;

    return _buildIndustrialContainer(
      isActive: true,
      activeColor: isNightOnly ? Colors.amberAccent : Colors.cyanAccent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security_update_good_rounded,
                    color: isNightOnly ? Colors.amberAccent : Colors.cyanAccent,
                    size: 14.sp,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "GLOBAL MOTION PROTOCOL",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isNightOnly ? Colors.amberAccent : Colors.cyanAccent)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (isNightOnly ? Colors.amberAccent : Colors.cyanAccent)
                            .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isNightOnly ? "NIGHT GATED" : "ALWAYS ACTIVE",
                  style: GoogleFonts.outfit(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    color: isNightOnly ? Colors.amberAccent : Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProtocolPill(
                  label: "ALWAYS ACTIVE",
                  subtitle: "24/7 Detection",
                  icon: Icons.wb_sunny_rounded,
                  isActive: !isNightOnly,
                  activeColor: Colors.cyanAccent,
                  onTap: () => notifier.setGlobalMotionMode(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProtocolPill(
                  label: "NIGHT ONLY",
                  subtitle: "18:00 - 06:00",
                  icon: Icons.nightlight_round,
                  isActive: isNightOnly,
                  activeColor: Colors.amberAccent,
                  onTap: () => notifier.setGlobalMotionMode(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolPill({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.heavy();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.white24,
              size: 20.sp,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : Colors.white24,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 7.sp,
                color: isActive ? activeColor.withOpacity(0.7) : Colors.white10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends ConsumerStatefulWidget {
  final String name;
  final SensorState sensor;
  final VoidCallback onAcknowledge;
  final Function(String) onRename;

  const _SensorCard({
    required this.name,
    required this.sensor,
    required this.onAcknowledge,
    required this.onRename,
  });

  @override
  ConsumerState<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends ConsumerState<_SensorCard> {
  void _showOptionsSheet(BuildContext context) {
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              (widget.sensor.nickname ?? widget.name).toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              ctx,
              icon: Icons.edit_rounded,
              label: "RENAME SENSOR",
              color: Colors.amberAccent,
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context);
              },
            ),
            const Divider(color: Colors.white10, height: 32),
            _buildOptionTile(
              ctx,
              icon: Icons.delete_forever_rounded,
              label: "DELETE SENSOR",
              color: Colors.redAccent,
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13.sp,
          letterSpacing: 1,
        ),
      ),
      onTap: () {
        HapticService.selection();
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Permanent Delete?",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          "Are you sure you want to remove this sensor from the ecosystem? This cannot be undone.",
          style: GoogleFonts.outfit(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(securityProvider.notifier).deleteSensor(widget.name);
              Navigator.pop(ctx);
            },
            child: Text(
              "DELETE",
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController(
      text: widget.sensor.nickname ?? widget.name,
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          title: Text(
            "Rename Sensor",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: _controller,
            autofocus: true,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter custom name",
              hintStyle: GoogleFonts.outfit(color: Colors.white24),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white12),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "CANCEL",
                style: GoogleFonts.outfit(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  widget.onRename(_controller.text.trim());
                }
                Navigator.pop(ctx);
              },
              child: Text(
                "SAVE",
                style: GoogleFonts.outfit(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMotion = widget.sensor.status;
    final lastTriggered = DateTime.fromMillisecondsSinceEpoch(
      widget.sensor.lastTriggered * 1000,
    );
    final timeStr =
        "${lastTriggered.hour.toString().padLeft(2, '0')}:${lastTriggered.minute.toString().padLeft(2, '0')}";
    final cleanName =
        widget.sensor.nickname ??
        widget.name
            .replaceAll('PIR', '')
            .replaceAll('_', ' ')
            .trim()
            .toUpperCase();

    final accentColor = hasMotion ? Colors.redAccent : Colors.cyanAccent;

    return GestureDetector(
      onLongPress: () => _showOptionsSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(hasMotion ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withOpacity(hasMotion ? 0.4 : 0.08),
            width: hasMotion ? 1.5 : 1.0,
          ),
          boxShadow: hasMotion
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(
                            ref.watch(
                                  securityProvider.select(
                                    (s) =>
                                        s.localArmStatus[widget.name] ?? true,
                                  ),
                                )
                                ? 0.12
                                : 0.05,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasMotion
                              ? Icons.motion_photos_on_rounded
                              : Icons.sensors_rounded,
                          size: 18.sp,
                          color: accentColor.withOpacity(
                            ref.watch(
                                  securityProvider.select(
                                    (s) =>
                                        s.localArmStatus[widget.name] ?? true,
                                  ),
                                )
                                ? 1.0
                                : 0.3,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.6, end: 1.0, duration: 1.5.seconds),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white24,
                      size: 20,
                    ),
                    onPressed: () => _showOptionsSheet(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.7,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final localArm = ref.watch(
                          securityProvider.select(
                            (s) => s.localArmStatus[widget.name] ?? true,
                          ),
                        );
                        return CupertinoSwitch(
                          value: localArm,
                          activeColor: Colors.redAccent,
                          onChanged: (v) {
                            HapticService.selection();
                            ref
                                .read(securityProvider.notifier)
                                .toggleSensorAlarm(widget.name);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                cleanName,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(hasMotion ? 1.0 : 0.8),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      timeStr == "00:00" ? "IDLE" : timeStr,
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary
                            .withOpacity(hasMotion ? 0.8 : 0.4),
                      ),
                    ),
                  ),
                  if (hasMotion)
                    Text(
                          "BREACH",
                          style: GoogleFonts.outfit(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1.seconds),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
