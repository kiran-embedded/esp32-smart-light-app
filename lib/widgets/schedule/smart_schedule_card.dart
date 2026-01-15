import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../models/switch_schedule.dart';
import '../../core/ui/responsive_layout.dart';

class SmartScheduleCard extends ConsumerWidget {
  const SmartScheduleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(switchScheduleProvider);
    final displaySettings = ref.watch(displaySettingsProvider);
    final scale = displaySettings.displayScale;

    // Find next upcoming schedule
    final now = DateTime.now();
    SwitchSchedule? nextSchedule;
    Duration? minDelta;

    for (final s in schedules) {
      if (!s.isEnabled) continue;

      final nextTime = _getNextOccurrence(s);
      final delta = nextTime.difference(now);

      if (minDelta == null || delta < minDelta) {
        minDelta = delta;
        nextSchedule = s;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(40 * scale),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40 * scale),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: EdgeInsets.all(30 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMART SCHEDULE',
                          style: GoogleFonts.outfit(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.4),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nextSchedule != null
                              ? 'Next Hub Event'
                              : 'System Sync Ready',
                          style: GoogleFonts.outfit(
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(nextSchedule != null, scale),
                  ],
                ),
                if (nextSchedule != null) ...[
                  const SizedBox(height: 32),
                  _buildTimeline(nextSchedule, minDelta!, scale),
                  const SizedBox(height: 32),
                  _buildEventDetails(nextSchedule, scale),
                ] else ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white.withOpacity(0.1),
                          size: 40 * scale,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All modules idling. No active timers.',
                          style: GoogleFonts.outfit(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildManageButton(context, scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _getNextOccurrence(SwitchSchedule s) {
    final now = DateTime.now();
    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      s.hour,
      s.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Widget _buildStatusBadge(bool active, double scale) {
    final color = active ? const Color(0xFF00FAFF) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: color, scale: scale),
          const SizedBox(width: 8),
          Text(
            active ? 'TRACKING' : 'IDLE',
            style: GoogleFonts.outfit(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w900,
              color: color.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(SwitchSchedule s, Duration delta, double scale) {
    final total = const Duration(hours: 24).inSeconds;
    final remaining = delta.inSeconds;
    final progress = (1.0 - (remaining / total)).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIMELINE PROGRESS',
              style: GoogleFonts.outfit(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            Text(
              '${delta.inHours}h ${delta.inMinutes % 60}m remaining',
              style: GoogleFonts.outfit(
                fontSize: 11 * scale,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF00FAFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 8 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8 * scale,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0080FF), Color(0xFF00FAFF)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FAFF).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Floating indicator
            Positioned(
              left: (progress * 100).toString() == '0.0' ? 0 : null,
              right: (progress * 100).toString() == '100.0' ? 0 : null,
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: Container(
                  width: 16 * scale,
                  height: 16 * scale,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventDetails(SwitchSchedule s, double scale) {
    return Row(
      children: [
        _buildDetailPill(
          Icons.av_timer,
          '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}',
          'EXECUTION',
          scale,
        ),
        const SizedBox(width: 16),
        _buildDetailPill(
          s.targetState ? Icons.bolt : Icons.power_off_rounded,
          s.targetState ? 'POWER ON' : 'POWER OFF',
          'ACTION',
          scale,
        ),
      ],
    );
  }

  Widget _buildDetailPill(
    IconData icon,
    String value,
    String label,
    double scale,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(24 * scale),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18 * scale,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 9 * scale,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageButton(BuildContext context, double scale) {
    return Container(
      width: double.infinity,
      height: 54 * scale,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20 * scale),
          onTap: () {
            // Navigation would happen here
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MANAGE HUB SCHEDULES',
                  style: GoogleFonts.outfit(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16 * scale,
                  color: Colors.white.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final double scale;
  const _PulseDot({required this.color, required this.scale});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8 * widget.scale,
          height: 8 * widget.scale,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.5 + 0.5 * _controller.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _controller.value),
                blurRadius: 10 * widget.scale,
                spreadRadius: 2 * widget.scale,
              ),
            ],
          ),
        );
      },
    );
  }
}
