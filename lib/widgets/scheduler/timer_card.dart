import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../providers/switch_provider.dart';
import '../../../../providers/switch_schedule_provider.dart';
import '../../../../models/switch_schedule.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/haptic_service.dart';
import '../../../../providers/settings_provider.dart';
import '../../../core/utils/app_icons.dart';
import '../common/aurexa_toggle.dart';
import '../scheduling/new_schedule_sheet.dart';

import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';

class TimerCard extends ConsumerStatefulWidget {
  final SwitchSchedule schedule;
  final Color? accent;
  final List<SwitchSchedule> allSchedules;

  const TimerCard({
    super.key,
    required this.schedule,
    this.accent,
    this.allSchedules = const [],
  });

  @override
  ConsumerState<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends ConsumerState<TimerCard> {
  bool _isDeleting = false;

  String _formatTime(int hour, int minute, TimeFormat format) {
    final dt = DateTime(2024, 1, 1, hour, minute);
    return DateFormat(
      format == TimeFormat.h24 ? 'HH:mm' : 'hh:mm a',
    ).format(dt);
  }

  String _frequencyLabel() {
    if (widget.schedule.days.isEmpty) return 'No days';
    if (widget.schedule.days.length == 7) return 'Daily';
    if (widget.schedule.days.length == 5 &&
        !widget.schedule.days.contains(6) &&
        !widget.schedule.days.contains(7)) {
      return 'Weekdays';
    }
    if (widget.schedule.days.length == 2 &&
        widget.schedule.days.contains(6) &&
        widget.schedule.days.contains(7)) {
      return 'Weekends';
    }
    return '${widget.schedule.days.length} days';
  }

  String _timeRangeLabel(TimeFormat format) {
    final start = _formatTime(
      widget.schedule.hour,
      widget.schedule.minute,
      format,
    );
    final pair = widget.allSchedules
        .where(
          (s) =>
              s.relayId == widget.schedule.relayId &&
              s.id != widget.schedule.id,
        )
        .firstOrNull;
    if (pair != null) {
      final end = _formatTime(pair.hour, pair.minute, format);
      return widget.schedule.targetState ? '$start -> $end' : '$end -> $start';
    }
    return '$start -> ${widget.schedule.targetState ? 'ON' : 'OFF'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final timeFormat = ref.watch(timeFormatProvider);

    final devices = ref.watch(switchDevicesProvider);
    final device = devices
        .where((d) => d.id == widget.schedule.relayId)
        .firstOrNull;

    final isActive = widget.schedule.isEnabled;
    final cardAccent = isActive
        ? (widget.accent ?? AppTheme.neonGreen)
        : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));

    final title = device?.name ?? 'Unknown Device';

    return GestureDetector(
      onLongPress: () {
        HapticService.heavy();
        setState(() => _isDeleting = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          ref
              .read(switchScheduleProvider.notifier)
              .deleteSchedule(widget.schedule.id);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF222222) : const Color(0xFFE8E8ED),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              if (_isDeleting)
                Positioned.fill(
                  child:
                      Container(
                            color: AppTheme.accentRed.withValues(alpha: 0.9),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOutBack,
                          ),
                ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cardAccent.withValues(alpha: isActive ? 0.95 : 0.55),
                        cardAccent.withValues(alpha: isActive ? 0.35 : 0.15),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cardAccent.withValues(
                          alpha: isActive ? 0.14 : 0.08,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        device != null
                            ? AppIcons.getIcon(device.iconKey, device.name)
                            : Icons.electrical_services_rounded,
                        color: isActive
                            ? cardAccent
                            : (isDark ? Colors.white38 : Colors.black38),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.white54 : Colors.black45),
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _frequencyLabel(),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : Colors.black45,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: isActive
                                    ? (isDark ? Colors.white : Colors.black)
                                    : (isDark
                                          ? Colors.white30
                                          : Colors.black38),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _timeRangeLabel(timeFormat),
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? (isDark ? Colors.white : Colors.black)
                                        : (isDark
                                              ? Colors.white38
                                              : Colors.black45),
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          _DayPills(
                            schedule: widget.schedule,
                            isActive: isActive,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  NewScheduleSheet(schedule: widget.schedule),
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: isDark ? Colors.white30 : Colors.black38,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AurexaToggle(
                          value: isActive,
                          width: 42,
                          height: 24,
                          onChanged: (val) {
                            HapticService.selection();
                            final updated = widget.schedule.copyWith(
                              isEnabled: val,
                            );
                            ref
                                .read(switchScheduleProvider.notifier)
                                .updateSchedule(updated);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPills extends StatelessWidget {
  final SwitchSchedule schedule;
  final bool isActive;
  final bool isDark;

  const _DayPills({
    required this.schedule,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isDayActive = schedule.days.contains(dayNum);

        final bg = isDayActive && isActive
            ? AppTheme.neonGreen.withValues(alpha: 0.14)
            : (isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6));
        final fg = isDayActive && isActive
            ? AppTheme.neonGreen
            : (isDark ? Colors.white38 : Colors.black38);

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 6 ? 3 : 0),
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              labels[index],
              style: GoogleFonts.outfit(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.1,
              ),
            ),
          ),
        );
      }),
    );
  }
}
