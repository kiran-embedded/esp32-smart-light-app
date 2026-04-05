import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                child: _buildMasterControl(
                  context,
                  securityState,
                  securityNotifier,
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 16.h)),

            // 2. ECOSYSTEM & AUTOMATION PILLS (VERTICAL)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildMasterLDR(context, securityState, ref),
                    const SizedBox(height: 12),
                    _buildActivePeriods(context, securityState, ref),
                    const SizedBox(height: 12),
                    _buildNeuralAutomationCard(context, ref, securityState),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 24.h)),

            // SENSOR GRID HEADER
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildGridHeader(securityState),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 16.h)),

            // SENSOR GRID
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
                        childAspectRatio: 1.0, // Taller cards for clearer names
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
                        );
                      }, childCount: securityState.sensors.length),
                    ),
            ),

            // PANIC / SOS SECTION
            SliverToBoxAdapter(child: SizedBox(height: 40.h)),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildSOSSlider(context, securityNotifier),
              ),
            ),

            // FOOTER SPACE FOR BOTTOM NAV
            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
          ],
        ),

        // ALARM OVERLAY (MODAL)
        if (securityState.isAlarmActive)
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

  Widget _buildMasterLDR(
    BuildContext context,
    SecurityState state,
    WidgetRef ref,
  ) {
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
                  Icon(
                    Icons.light_mode_rounded,
                    color: Colors.amberAccent,
                    size: 16.sp,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "ECOSYSTEM LDR LINK",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white38,
                      letterSpacing: 1,
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
                // Realistic slide feel intelligence
                if (val.toInt() % 5 == 0) {
                  HapticService.light();
                }
                ref
                    .read(securityProvider.notifier)
                    .updateLdrThreshold(val.toInt());
              },
              onChangeEnd: (val) {
                HapticService.medium();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralAutomationCard(
    BuildContext context,
    WidgetRef ref,
    SecurityState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: state.autoLightOnMotion
            ? Colors.cyanAccent.withOpacity(0.08)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: state.autoLightOnMotion
              ? Colors.cyanAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.bolt_rounded,
                color: state.autoLightOnMotion
                    ? Colors.cyanAccent
                    : Colors.white24,
                size: 18.sp,
              ),
              Switch.adaptive(
                value: state.autoLightOnMotion,
                activeColor: Colors.cyanAccent,
                onChanged: (_) {
                  HapticService.medium();
                  ref.read(securityProvider.notifier).toggleAutoLightOnMotion();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "NEURAL LIGHT",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: state.autoLightOnMotion ? Colors.cyanAccent : Colors.white,
            ),
          ),
          Text(
            "Auto-Light on Motion",
            style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePeriods(
    BuildContext context,
    SecurityState state,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            "ALARM ACTIVE SCHEDULE",
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              _buildIosRowCell(
                'morning',
                Icons.wb_twilight,
                'Morning (6:00 AM - 11:59 AM)',
                state,
                ref,
              ),
              const Divider(color: Colors.white10, height: 1, indent: 48),
              _buildIosRowCell(
                'afternoon',
                Icons.wb_sunny,
                'Afternoon (12:00 PM - 4:59 PM)',
                state,
                ref,
              ),
              const Divider(color: Colors.white10, height: 1, indent: 48),
              _buildIosRowCell(
                'evening',
                Icons.nights_stay_outlined,
                'Evening (5:00 PM - 7:59 PM)',
                state,
                ref,
              ),
              const Divider(color: Colors.white10, height: 1, indent: 48),
              _buildIosRowCell(
                'night',
                Icons.nightlight_round,
                'Night (8:00 PM - 11:59 PM)',
                state,
                ref,
              ),
              const Divider(color: Colors.white10, height: 1, indent: 48),
              _buildIosRowCell(
                'midnight',
                Icons.star,
                'Midnight (12:00 AM - 5:59 AM)',
                state,
                ref,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIosRowCell(
    String periodKey,
    IconData icon,
    String label,
    SecurityState state,
    WidgetRef ref, {
    bool isLast = false,
  }) {
    final isActive = state.activePeriods[periodKey] ?? true;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        ref
            .read(securityProvider.notifier)
            .setPeriodActive(periodKey, !isActive);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.blueAccent.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.blueAccent : Colors.white38,
                size: 18.sp,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
            ),
            Switch.adaptive(
              value: isActive,
              activeColor: Colors.blueAccent,
              onChanged: (_) {
                HapticService.medium();
                ref
                    .read(securityProvider.notifier)
                    .setPeriodActive(periodKey, !isActive);
              },
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
            color: Colors.white24,
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
}

class _SensorCard extends StatefulWidget {
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
  State<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<_SensorCard> {
  void _showRenameDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController(
      text: widget.sensor.nickname ?? widget.name,
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            "Rename Sensor",
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          content: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter custom name",
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  widget.onRename(_controller.text.trim());
                }
                Navigator.pop(ctx);
              },
              child: const Text(
                "SAVE",
                style: TextStyle(color: Colors.cyanAccent),
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

    return GestureDetector(
      onLongPress: () {
        HapticService.pulse();
        _showRenameDialog(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: (hasMotion ? Colors.redAccent : Colors.cyanAccent).withOpacity(
            0.04,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (hasMotion ? Colors.redAccent : Colors.cyanAccent)
                .withOpacity(hasMotion ? 0.2 : 0.08),
            width: 1,
          ),
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
                          color:
                              (hasMotion ? Colors.redAccent : Colors.cyanAccent)
                                  .withOpacity(0.12),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (hasMotion
                                          ? Colors.redAccent
                                          : Colors.cyanAccent)
                                      .withOpacity(0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          hasMotion
                              ? Icons.motion_photos_on_rounded
                              : Icons.sensors_rounded,
                          size: 18.sp,
                          color: hasMotion
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.6, end: 1.0, duration: 1.5.seconds),
                  if (hasMotion)
                    Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(duration: 80.ms)
                        .fadeOut(),
                ],
              ),
              const Spacer(),
              Text(
                cleanName,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  timeStr == "00:00" ? "IDLE" : timeStr,
                  style: GoogleFonts.outfit(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
