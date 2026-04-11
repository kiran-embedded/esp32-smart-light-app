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
  final VoidCallback onDelete;
  final VoidCallback? onCalibrate;
  final VoidCallback? onRename;

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
    required this.onDelete,
    this.onCalibrate,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () {
          HapticService.heavy();
          _showSensorOptions(context);
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
              // ── SENSOR ICON ──
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

              // ── INFO ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isAlarmEnabled ? Colors.white : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status
                          ? "ALERT - MOTION DETECTED"
                          : (isAlarmEnabled ? "SECURE" : "NODE SILENCED"),
                      style: TextStyle(
                        color: status
                            ? Colors.redAccent
                            : (isAlarmEnabled
                                  ? Colors.greenAccent.withOpacity(0.8)
                                  : Colors.white24),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ── INLINE ALARM TOGGLE ──
              GestureDetector(
                onTap: () {
                  HapticService.toggle(!isAlarmEnabled);
                  onToggleAlarm();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAlarmEnabled
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAlarmEnabled
                          ? Colors.greenAccent.withOpacity(0.3)
                          : Colors.white12,
                    ),
                  ),
                  child: Icon(
                    isAlarmEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: isAlarmEnabled ? Colors.greenAccent : Colors.white24,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // ── MORE OPTIONS ──
              IconButton(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white24,
                  size: 20,
                ),
                onPressed: () {
                  HapticService.selection();
                  _showSensorOptions(context);
                },
              ),

              // ── ACKNOWLEDGE (only when alert is active) ──
              if (status) ...[
                const SizedBox(width: 4),
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

  void _showSensorOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // ── Toggle Alarm ──
            ListTile(
              leading: Icon(
                isAlarmEnabled
                    ? Icons.notifications_off_rounded
                    : Icons.notifications_active_rounded,
                color: Colors.cyanAccent,
              ),
              title: Text(
                isAlarmEnabled ? "Disable Phone Alerts" : "Enable Phone Alerts",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                isAlarmEnabled ? "Currently active" : "Currently silenced",
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
              onTap: () {
                HapticService.toggle(!isAlarmEnabled);
                Navigator.pop(context);
                onToggleAlarm();
              },
            ),
            const Divider(height: 1, color: Colors.white10),

            // ── Rename ──
            if (onRename != null)
              ListTile(
                leading: const Icon(
                  Icons.edit_rounded,
                  color: Colors.amberAccent,
                ),
                title: const Text(
                  "Rename Sensor",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  HapticService.impactClick();
                  Navigator.pop(context);
                  onRename!();
                },
              ),

            // ── Calibration ──
            if (onCalibrate != null) ...[
              const Divider(height: 1, color: Colors.white10),
              ListTile(
                leading: const Icon(
                  Icons.settings_input_antenna_rounded,
                  color: Colors.cyanAccent,
                ),
                title: const Text(
                  "Calibration Hub",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Adjust PIR sensitivity & debounce",
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
                onTap: () {
                  HapticService.impactClick();
                  Navigator.pop(context);
                  onCalibrate!();
                },
              ),
            ],

            const Divider(height: 1, color: Colors.white10),

            // ── Delete ──
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                "Delete Sensor Permanently",
                style: TextStyle(color: Colors.redAccent),
              ),
              subtitle: const Text(
                "This action cannot be undone",
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
              onTap: () {
                HapticService.impactWarning();
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
