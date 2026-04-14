import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptic_service.dart';
import '../../core/system/display_engine.dart';

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
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onLongPress: () {
          HapticService.heavy();
          _showSensorOptions(context);
        },
        child: Container(
          padding: EdgeInsets.all(16.p),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: Border.all(
              color: status
                  ? Colors.redAccent
                  : (isAlarmEnabled
                        ? Colors.white10
                        : Colors.white.withOpacity(0.03)),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              // ── DIAGNOSTIC STATUS ICON ──
              _buildDiagnosticIcon(),
              SizedBox(width: 16.w),

              // ── INFO HUB ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: GoogleFonts.shareTechMono(
                        color: isAlarmEnabled ? Colors.white : Colors.white24,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _buildBadge(
                          status
                              ? "BREACH_ACTIVE"
                              : (isAlarmEnabled ? "MONITORING" : "SILENCED"),
                          status
                              ? Colors.redAccent
                              : (isAlarmEnabled
                                    ? Colors.greenAccent
                                    : Colors.white10),
                        ),
                        if (status) ...[
                          SizedBox(width: 8.w),
                          _buildBadge("0x$triggerCount", Colors.redAccent),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── ACTION CLUSTERS ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status)
                    _buildIconButton(
                      Icons.check_circle_outline_rounded,
                      Colors.white,
                      onAcknowledge,
                    ),
                  SizedBox(width: 8.w),
                  _buildIconButton(
                    isAlarmEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    isAlarmEnabled ? Colors.greenAccent : Colors.white24,
                    () {
                      HapticService.toggle(!isAlarmEnabled);
                      onToggleAlarm();
                    },
                    isPill: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: status
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: status ? Colors.redAccent : Colors.white10,
                  width: 1.0,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status ? Icons.radar_rounded : Icons.sensors_rounded,
                color: status ? Colors.redAccent : Colors.white24,
                size: 18.sp,
              ),
            )
            .animate(target: status ? 1 : 0)
            .shimmer(duration: 800.ms, color: Colors.white10),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(2.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.shareTechMono(
          color: color.withOpacity(0.8),
          fontSize: 8.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isPill = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.p),
        decoration: BoxDecoration(
          color: isPill ? color.withOpacity(0.05) : Colors.transparent,
          border: Border.all(
            color: isPill ? color.withOpacity(0.2) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: color, size: 16.sp),
      ),
    );
  }

  void _showSensorOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.p),
        decoration: BoxDecoration(
          color: const Color(0xFF070707),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 2.h,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "NODE_ABSTRACTION: ${name.toUpperCase()}",
              style: GoogleFonts.shareTechMono(
                color: Colors.white38,
                fontSize: 10.sp,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 24.h),
            _buildOptionTile(
              Icons.edit_note_rounded,
              "RENAME_NODE",
              onRename,
              color: Colors.cyanAccent,
            ),
            _buildOptionTile(
              Icons.delete_sweep_rounded,
              "DELETE_NODE",
              onDelete,
              color: Colors.redAccent,
              isDestructive: true,
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    required Color color,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 18.sp),
      title: Text(
        label,
        style: GoogleFonts.shareTechMono(
          color: isDestructive ? color : Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}
