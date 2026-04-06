import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

class SensorCard extends StatelessWidget {
  final String name;
  final bool status;
  final int lastTriggered;
  final int lightLevel;
  final bool isAlarmEnabled;
  final int triggerCount;
  final VoidCallback onAcknowledge;
  final VoidCallback onToggleAlarm;

  const SensorCard({
    super.key,
    required this.name,
    required this.status,
    required this.lastTriggered,
    required this.lightLevel,
    required this.isAlarmEnabled,
    required this.triggerCount,
    required this.onAcknowledge,
    required this.onToggleAlarm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onLongPress: () {
          HapticService.heavy();
          onToggleAlarm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAlarmEnabled
                    ? "Alarm Disabled for $name"
                    : "Alarm Enabled for $name",
                style: const TextStyle(color: Colors.cyanAccent),
              ),
              backgroundColor: Colors.black87,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAlarmEnabled
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.02),
            border: Border.all(
              color: status
                  ? Colors.redAccent.withOpacity(0.5)
                  : (isAlarmEnabled
                        ? Colors.white10
                        : Colors.white.withOpacity(0.05)),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: status
                          ? Colors.redAccent.withOpacity(0.2)
                          : (isAlarmEnabled
                                ? Colors.greenAccent.withOpacity(0.1)
                                : Colors.white.withOpacity(0.05)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status
                          ? Icons.warning_rounded
                          : (isAlarmEnabled
                                ? Icons.shield_rounded
                                : Icons.shield_outlined),
                      color: status
                          ? Colors.redAccent
                          : (isAlarmEnabled
                                ? Colors.greenAccent
                                : Colors.white24),
                      size: 28,
                    ),
                  ),
                  if (triggerCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          triggerCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isAlarmEnabled ? Colors.white : Colors.white38,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status
                          ? "ALERT - MOTION DETECTED"
                          : (isAlarmEnabled
                                ? "SECURE | Light: $lightLevel%"
                                : "NODE SILENCED"),
                      style: TextStyle(
                        color: status
                            ? Colors.redAccent
                            : (isAlarmEnabled
                                  ? Colors.greenAccent.withOpacity(0.8)
                                  : Colors.white24),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isAlarmEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: isAlarmEnabled ? Colors.white30 : Colors.white12,
                size: 18,
              ),
              if (status) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    HapticService.selection();
                    onAcknowledge();
                  },
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white70,
                  ),
                  tooltip: 'Acknowledge Alert',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
