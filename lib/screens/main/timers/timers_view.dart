import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/common/aurexa_app_bar.dart';
import '../../../widgets/timers/timers_hero_banner.dart';
import '../../../widgets/scheduler/timer_card.dart';
import '../../../providers/switch_schedule_provider.dart';
import '../../../models/switch_schedule.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/scheduling/new_schedule_sheet.dart';
import '../../../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TimersView extends ConsumerStatefulWidget {
  const TimersView({super.key});

  @override
  ConsumerState<TimersView> createState() => _TimersViewState();
}

class _TimersViewState extends ConsumerState<TimersView> {
  int _filterIndex = 0;

  void _showAddTimer(BuildContext context) {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewScheduleSheet(),
    );
  }

  List<SwitchSchedule> _filteredSchedules(List<SwitchSchedule> all) {
    switch (_filterIndex) {
      case 1:
        return all;
      case 2:
        return all.where((s) => s.days.isEmpty).toList();
      case 3:
        return all
            .where((s) => s.hour == 6 || s.hour == 18 || s.hour == 19)
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allSchedules = ref.watch(switchScheduleProvider);
    final schedules = _filteredSchedules(allSchedules);

    final active = schedules.where((s) => s.isEnabled).toList();
    final inactive = schedules.where((s) => !s.isEnabled).toList();

    final activePreview = active.take(3).toList();
    final inactivePreview = inactive.take(2).toList();

    return Column(
      children: [
        AurexaAppBar(
          actions: [
            GestureDetector(
              onTap: () => _showAddTimer(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.brandGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4000E676),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = (constraints.maxHeight * 0.012).clamp(4.0, 8.0);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const TimersHeroBanner(),
                    SizedBox(height: gap),
                    _TimerFilterRow(
                      selectedIndex: _filterIndex,
                      isDark: isDark,
                      onSelected: (i) => setState(() => _filterIndex = i),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      flex: 5,
                      child: _TimerSection(
                        title: 'Active Timers',
                        count: active.length,
                        accentColor: AppTheme.neonGreen,
                        isDark: isDark,
                        schedules: activePreview,
                        allSchedules: schedules,
                        emptyLabel: 'No active timers',
                        accentPalette: AppTheme.switchAccentPalette,
                      ),
                    ),
                    SizedBox(height: gap * 0.8),
                    Expanded(
                      flex: 3,
                      child: _TimerSection(
                        title: 'Inactive Timers',
                        count: inactive.length,
                        accentColor: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                        isDark: isDark,
                        schedules: inactivePreview,
                        allSchedules: schedules,
                        emptyLabel: 'No inactive timers',
                        accentPalette: const [
                          Color(0xFF9CA3AF),
                          Color(0xFF9CA3AF),
                        ],
                      ),
                    ),
                    SizedBox(height: gap * 0.4),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimerFilterRow extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onSelected;

  const _TimerFilterRow({
    required this.selectedIndex,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterPill(
            label: 'All Timers',
            icon: Icons.access_time_filled_rounded,
            isSelected: selectedIndex == 0,
            isDark: isDark,
            useGradient: true,
            onTap: () => onSelected(0),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Schedules',
            icon: Icons.calendar_today_rounded,
            isSelected: selectedIndex == 1,
            isDark: isDark,
            onTap: () => onSelected(1),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Countdown',
            icon: Icons.timer_outlined,
            isSelected: selectedIndex == 2,
            isDark: isDark,
            onTap: () => onSelected(2),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Sunrise/Sunset',
            icon: Icons.wb_twilight_rounded,
            isSelected: selectedIndex == 3,
            isDark: isDark,
            onTap: () => onSelected(3),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final bool useGradient;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    this.useGradient = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = isSelected && useGradient;
    final borderColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFD1D1D6);
    final textColor = active
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);
    final iconColor = active
        ? Colors.white
        : (isDark ? Colors.white54 : Colors.black54);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.brandGradient : null,
          color: active
              ? null
              : (isDark ? const Color(0xFF111111) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.transparent : borderColor,
            width: 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppTheme.neonGreen.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerSection extends StatelessWidget {
  final String title;
  final int count;
  final Color accentColor;
  final bool isDark;
  final List<SwitchSchedule> schedules;
  final List<SwitchSchedule> allSchedules;
  final String emptyLabel;
  final List<Color> accentPalette;

  const _TimerSection({
    required this.title,
    required this.count,
    required this.accentColor,
    required this.isDark,
    required this.schedules,
    required this.allSchedules,
    required this.emptyLabel,
    required this.accentPalette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'View All >',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.neonGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: schedules.isEmpty
              ? Center(
                  child: Text(
                    emptyLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: schedules.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < schedules.length - 1 ? 6 : 0,
                      ),
                      child: TimerCard(
                        schedule: schedules[i],
                        allSchedules: allSchedules,
                        accent: accentPalette[i % accentPalette.length],
                      ).animate(key: ValueKey(schedules[i].id)).fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutQuad),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

