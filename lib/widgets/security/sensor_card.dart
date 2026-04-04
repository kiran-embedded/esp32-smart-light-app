import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

class SensorCard extends StatelessWidget {
  final String name;
  final bool status;
  final int lastTriggered;
  final int lightLevel;
  final VoidCallback onAcknowledge;

  const SensorCard({
    super.key,
    required this.name,
    required this.status,
    required this.lastTriggered,
    required this.lightLevel,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: status ? Colors.redAccent.withOpacity(0.5) : Colors.white10,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: status
                    ? Colors.redAccent.withOpacity(0.2)
                    : Colors.greenAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status ? Icons.warning_rounded : Icons.shield_rounded,
                color: status ? Colors.redAccent : Colors.greenAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status
                        ? "ALERT - MOTION DETECTED"
                        : "SECURE | Light: $lightLevel%",
                    style: TextStyle(
                      color: status
                          ? Colors.redAccent
                          : Colors.greenAccent.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (status)
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
        ),
      ),
    );
  }
}
