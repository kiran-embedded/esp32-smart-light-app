import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/switch_history_provider.dart';
import '../../providers/switch_provider.dart';
import '../../core/ui/responsive_layout.dart';

class HistorySheet extends ConsumerWidget {
  final String deviceId;

  const HistorySheet({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(switchHistoryProvider(deviceId));
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'ACTIVITY TRANSCRIPTS',
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.w,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Real-time stream of module events',
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: history.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: history.length,
                    padding: EdgeInsets.only(bottom: 30.h),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final event = history[index];
                      return _buildHistoryItem(event, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static final DateFormat _timeFormat = DateFormat('hh:mm:ss a');
  static final DateFormat _dateFormat = DateFormat('MMM dd');

  Widget _buildHistoryItem(dynamic event, ThemeData theme) {
    final bool isOn = event.state;
    final color = isOn ? Colors.cyanAccent : Colors.white24;
    final timeStr = _timeFormat.format(event.timestamp);
    final dateStr = _dateFormat.format(event.timestamp);

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOn ? Icons.power_rounded : Icons.power_off_rounded,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final devices = ref.watch(switchDevicesProvider);
                      final device = devices.firstWhere(
                        (d) => d.id == event.relayId,
                        orElse: () => devices.first,
                      );
                      final displayName =
                          event.relayName ?? device.nickname ?? device.name;

                      return Text(
                        '$displayName turned ${isOn ? "ON" : "OFF"}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  Text(
                    'Triggered via ${event.triggeredBy}',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 11.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.roboto(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.roboto(
                    color: Colors.white24,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 60.sp,
            color: Colors.white10,
          ),
          SizedBox(height: 16.h),
          Text(
            'No history data yet',
            style: GoogleFonts.outfit(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
