import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/security_provider.dart';
import '../../widgets/security/sensor_card.dart';
import '../../widgets/security/security_history_view.dart';
import '../../services/haptic_service.dart';
import '../../widgets/security/calibration_panel.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);
    final sensors = securityState.sensors;
    final isArmed = securityState.isArmed;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Security Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isArmed ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: isArmed
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => ref.read(securityProvider.notifier).toggleArmed(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Arm/Disarm Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isArmed
                          ? Colors.redAccent.withOpacity(0.05)
                          : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isArmed
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArmed ? 'NEBULA ARMED' : 'NEBULA DISARMED',
                              style: TextStyle(
                                color: isArmed
                                    ? Colors.redAccent
                                    : Theme.of(context).colorScheme.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              isArmed
                                  ? 'Real-time breach detection active'
                                  : 'Sensors monitoring only',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: isArmed,
                          activeColor: Colors.redAccent,
                          onChanged: (_) =>
                              ref.read(securityProvider.notifier).toggleArmed(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMascot(context),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Advanced Security Settings
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: Colors.cyanAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ACTIVATION STRATEGY',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActivationStrategy(
                          context,
                          ref,
                          securityState.securityMode,
                          securityState.ldrThreshold,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Colors.white10),
                        const SizedBox(height: 16),
                        _buildSettingsRow(
                          context,
                          'Mute Hardware Buzzer',
                          'Silence physical beeps on ESP32',
                          Icons.volume_off_rounded,
                          securityState.isBuzzerMuted,
                          (val) => ref
                              .read(securityProvider.notifier)
                              .toggleBuzzerMute(),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsRow(
                          context,
                          'Native Alarm Overlay',
                          'Full-screen UI vs Notifications',
                          Icons.notifications_active_rounded,
                          securityState.isNativeAlarmEnabled,
                          (val) => ref
                              .read(securityProvider.notifier)
                              .toggleNativeAlarm(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // System Vitality Dashboard v1.6.8
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildVitalityCard(context, securityState),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // PIR CALIBRATION HUB (Embedded - Elevated Visibility)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.04,
                      ), // Increased from 0.01
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ), // Increased from 0.04
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: Colors.orangeAccent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "DIAGNOSTIC CALIBRATION",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "v1.9.7 PRO",
                              style: GoogleFonts.shareTechMono(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const CalibrationPanel(),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Sensors',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: securityState.isHubOnline
                              ? Colors.green.withOpacity(0.15)
                              : Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: securityState.isHubOnline
                                ? Colors.green.withOpacity(0.3)
                                : Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          securityState.isHubOnline
                              ? 'NODE ONLINE'
                              : 'NODE OFFLINE',
                          style: TextStyle(
                            color: securityState.isHubOnline
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (sensors.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sensors_off_rounded,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "PIR Sensors Offline",
                          style: TextStyle(
                            color: Colors.white38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Use 'System Test Suite' below to simulate activity",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final id = sensors.keys.elementAt(index);
                      final state = sensors[id]!;
                      return RepaintBoundary(
                            child: SensorCard(
                              name: id.toUpperCase(),
                              status: state.status,
                              lastTriggered: state.lastTriggered,
                              lightLevel: state.lightLevel,
                              isAlarmEnabled: state.isAlarmEnabled,
                              triggerCount: state.triggerCount,
                              onAcknowledge: () => ref
                                  .read(securityProvider.notifier)
                                  .acknowledge(id),
                              onToggleAlarm: () => ref
                                  .read(securityProvider.notifier)
                                  .toggleSensorAlarm(id),
                              onDelete: () => _showDeleteSensorDialog(
                                context,
                                ref,
                                id,
                                securityState.sensors[id]?.nickname ?? id,
                              ),
                              onRename: () {
                                _showRenameSensorDialog(
                                  context,
                                  ref,
                                  id,
                                  securityState.sensors[id]?.nickname ?? id,
                                );
                              },
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 80.ms, delay: (index * 50).ms)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          );
                    }, childCount: sensors.length),
                  ),
                ),

              // SYSTEM TEST SUITE (Manual Simulation)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.01),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.biotech_rounded,
                              color: Colors.orangeAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "SYSTEM TEST SUITE",
                              style: GoogleFonts.outfit(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: sensors.keys
                              .map((id) => _buildTestButton(id))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // History Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${securityState.logs.length} events',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SecurityHistoryView(logs: securityState.logs),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),
        ),
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
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.greenAccent : Colors.white24,
                          shape: BoxShape.circle,
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        duration: 1.seconds,
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                      )
                      .then()
                      .scale(duration: 1.seconds),
                  const SizedBox(width: 8),
                  Text(
                    'SYSTEM VITALITY',
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              Text(
                isOnline ? 'LIVE SYNC' : 'OFFLINE',
                style: TextStyle(
                  color: isOnline ? Colors.greenAccent : Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // WiFi Signal
              Expanded(
                child: _buildVitalTile(
                  context,
                  'SIGNAL',
                  '${rssi}dBm',
                  getRssiIcon(rssi),
                  getRssiColor(rssi),
                ),
              ),
              const SizedBox(width: 12),
              // Sensor Health
              Expanded(
                child: _buildVitalTile(
                  context,
                  'LDR OPTIC',
                  isLdrOk ? 'NOMINAL' : 'HARDWARE FAIL',
                  Icons.lens_blur_rounded,
                  isLdrOk ? Colors.cyanAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String zone) {
    final sensors = ref.watch(securityProvider).sensors;
    final isActive = sensors[zone]?.status ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(securityProvider.notifier).simulateTrigger(zone, !isActive);
        },
        onLongPress: () {
          HapticService.heavy();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF121212),
              title: const Text(
                "Delete Sensor?",
                style: TextStyle(color: Colors.white),
              ),
              content: Text("Are you sure you want to remove $zone?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(securityProvider.notifier).deleteSensor(zone);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.redAccent.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.white10,
            ),
          ),
          child: Text(
            zone,
            style: TextStyle(
              color: isActive ? Colors.redAccent : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivationStrategy(
    BuildContext context,
    WidgetRef ref,
    int currentMode,
    int ldrThreshold,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _strategyPill(
              context,
              ref,
              3,
              'ALWAYS',
              Icons.security_rounded,
              currentMode == 3,
            ),
            _strategyPill(
              context,
              ref,
              0,
              'DARKNESS',
              Icons.nights_stay_rounded,
              currentMode == 0,
            ),
            _strategyPill(
              context,
              ref,
              1,
              'SCHEDULE',
              Icons.schedule_rounded,
              currentMode == 1,
            ),
            _strategyPill(
              context,
              ref,
              2,
              'HYBRID',
              Icons.hub_rounded,
              currentMode == 2,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Simple Description
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(currentMode),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  _getModeIcon(currentMode),
                  color: Colors.cyanAccent.withOpacity(0.5),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getModeDescription(currentMode),
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (currentMode == 0 || currentMode == 2) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                "LDR SENSITIVITY",
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                "${ldrThreshold}% DARK",
                style: GoogleFonts.outfit(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSensitivitySelector(context, ref, ldrThreshold),
        ],
      ],
    );
  }

  Widget _strategyPill(
    BuildContext context,
    WidgetRef ref,
    int mode,
    String label,
    IconData icon,
    bool isActive,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          ref.read(securityProvider.notifier).setSecurityMode(mode);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.cyanAccent.withOpacity(0.15)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive
                      ? Colors.cyanAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? Colors.cyanAccent : Colors.white24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? Colors.white : Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivitySelector(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    final levels = {20: 'LOW', 50: 'MID', 80: 'HIGH'};
    return Row(
      children: levels.entries.map((e) {
        final isSel = current == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticService.light();
              ref.read(securityProvider.notifier).updateLdrThreshold(e.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel ? Colors.white24 : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: GoogleFonts.outfit(
                    color: isSel ? Colors.white : Colors.white12,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getModeIcon(int mode) {
    switch (mode) {
      case 0:
        return Icons.nights_stay_rounded;
      case 1:
        return Icons.schedule_rounded;
      case 2:
        return Icons.hub_rounded;
      case 3:
        return Icons.security_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _getModeDescription(int mode) {
    switch (mode) {
      case 0:
        return "DARKNESS: Security only activates when environmental light drops below threshold.";
      case 1:
        return "SCHEDULE: Security only activates during your defined time-slots.";
      case 2:
        return "HYBRID: Both conditions must be met (Time & Darkness). Maximum reliability.";
      case 3:
        return "ALWAYS: Maximum Security. System is active 24/7 regardless of light or time.";
      default:
        return "";
    }
  }

  Widget _buildSettingsRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showDeleteSensorDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        title: Text(
          "Delete Sensor?",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to permanently remove $name from the system?",
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(securityProvider.notifier).deleteSensor(id);
              Navigator.pop(context);
            },
            child: Text(
              "DELETE",
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameSensorDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Text(
          "Rename Sensor",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new name",
            hintStyle: GoogleFonts.outfit(color: Colors.white24),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(securityProvider.notifier)
                    .renameSensor(id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(
              "SAVE",
              style: GoogleFonts.outfit(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cyber Grid Background
          Opacity(
            opacity: 0.1,
            child: const Icon(
              Icons.grid_4x4_rounded,
              size: 200,
              color: Colors.blue,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                    Icons.shield_rounded,
                    size: 40,
                    color: Colors.cyanAccent,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2.seconds)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1.seconds,
                  ),
              const SizedBox(height: 8),
              Text(
                "NEBULA CORE V1.6.8",
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent.withOpacity(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              Text(
                "Sovereign Security Protocol Active",
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
