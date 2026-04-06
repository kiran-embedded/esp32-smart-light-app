import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/security_provider.dart';
import '../../widgets/security/sensor_card.dart';
import '../../widgets/security/security_history_view.dart';
import '../../services/sound_service.dart';
import 'alarm_screen.dart';

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

    // Monitor for active alarms to play sound and show UI
    ref.listen(securityProvider, (previous, next) {
      if (next.isArmed) {
        next.sensors.forEach((key, value) {
          if (value.status &&
              (previous == null || !previous.sensors[key]!.status)) {
            // Trigger sound based on sensor
            if (key.toLowerCase().contains('kitchen')) {
              ref.read(soundServiceProvider).playAlarmHigh();
            } else {
              ref.read(soundServiceProvider).playAlarmMedium();
            }

            // Show Alarm Screen if in foreground
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AlarmScreen(zone: key.toUpperCase()),
              ),
            );
          }
        });
      }
    });

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
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArmed ? 'SYSTEM ARMED' : 'SYSTEM DISARMED',
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
                            'Nebula Protection Active',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
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

              // Calibration Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.light_mode_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LDR CALIBRATION',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${securityState.ldrThreshold}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: securityState.ldrThreshold.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 10,
                          label: securityState.ldrThreshold.toString(),
                          onChanged: (val) => ref
                              .read(securityProvider.notifier)
                              .updateLdrThreshold(val.toInt()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Sensors Section
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
                          color: securityState.isNodeActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: securityState.isNodeActive
                                ? Colors.green.withOpacity(0.3)
                                : Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          securityState.isNodeActive
                              ? 'NODE ONLINE'
                              : 'NODE OFFLINE',
                          style: TextStyle(
                            color: securityState.isNodeActive
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final key = sensors.keys.elementAt(index);
                      final state = sensors[key]!;
                      return RepaintBoundary(
                            child: SensorCard(
                              name: key.toUpperCase(),
                              status: state.status,
                              lastTriggered: state.lastTriggered,
                              lightLevel: state.lightLevel,
                              isAlarmEnabled: state.isAlarmEnabled,
                              triggerCount: state.triggerCount,
                              onAcknowledge: () => ref
                                  .read(securityProvider.notifier)
                                  .acknowledge(key),
                              onToggleAlarm: () => ref
                                  .read(securityProvider.notifier)
                                  .toggleSensorAlarm(key),
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
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.biotech_rounded,
                              color: Colors.orangeAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "SYSTEM TEST SUITE",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Manually simulate sensor triggers to verify alarm logic and UI responses.",
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildTestButton("living"),
                            _buildTestButton("kitchen"),
                            _buildTestButton("hallway"),
                            _buildTestButton("garage"),
                            _buildTestButton("door"),
                          ],
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

  Widget _buildTestButton(String zone) {
    final sensors = ref.watch(securityProvider).sensors;
    final isActive = sensors[zone]?.status ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(securityProvider.notifier).simulateTrigger(zone, !isActive);
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
}
