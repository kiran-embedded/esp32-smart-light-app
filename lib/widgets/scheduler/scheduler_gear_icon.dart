import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/haptic_service.dart';

class SchedulerGearIcon extends StatefulWidget {
  final VoidCallback onTap;
  final bool isEnabled;

  const SchedulerGearIcon({
    super.key,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  State<SchedulerGearIcon> createState() => _SchedulerGearIconState();
}

class _SchedulerGearIconState extends State<SchedulerGearIcon> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: () {
        HapticService.medium();
        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child:
            Icon(
                  Icons.access_time_filled_rounded,
                  size: 20,
                  color: widget.isEnabled ? primaryColor : Colors.white38,
                )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: 10.seconds),
      ),
    );
  }
}
