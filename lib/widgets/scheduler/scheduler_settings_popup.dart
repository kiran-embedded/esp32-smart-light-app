import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/switch_schedule.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../providers/switch_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/scheduler_service.dart';
import '../../core/ui/responsive_layout.dart';
import '../../providers/switch_settings_provider.dart';
import '../../providers/animation_provider.dart';
// import '../common/frosted_glass.dart'; // Removed
import '../common/pixel_led_border.dart';

class SchedulerSettingsPopup extends ConsumerStatefulWidget {
  final String? initialDeviceId;
  const SchedulerSettingsPopup({super.key, this.initialDeviceId});

  @override
  ConsumerState<SchedulerSettingsPopup> createState() =>
      _SchedulerSettingsPopupState();
}

class _SchedulerSettingsPopupState
    extends ConsumerState<SchedulerSettingsPopup> {
  final List<String> _selectedScheduleIds = [];
  bool _isMultiSelectMode = false;

  void _toggleMultiSelect(String id) {
    setState(() {
      if (_selectedScheduleIds.contains(id)) {
        _selectedScheduleIds.remove(id);
        if (_selectedScheduleIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedScheduleIds.add(id);
        _isMultiSelectMode = true;
      }
    });
    HapticService.selection();
  }

  void _deleteSelected() {
    if (_selectedScheduleIds.isNotEmpty) {
      ref
          .read(switchScheduleProvider.notifier)
          .deleteSchedules(_selectedScheduleIds);
      _selectedScheduleIds.clear();
    }
    setState(() {
      _isMultiSelectMode = false;
    });
    HapticService.heavy();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF000000), // Pure OLED Black
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildDragHandle(),
            _buildHeader(),
            Expanded(child: RepaintBoundary(child: _buildSchedulesList())),
            _buildFooterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _isMultiSelectMode
                              ? const Color(0xFFFF4D4D) // Neon Red
                              : Theme.of(context).primaryColor, // Dynamic Theme
                          (_isMultiSelectMode
                                  ? const Color(0xFFFF4D4D)
                                  : Theme.of(context).primaryColor)
                              .withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isMultiSelectMode
                                      ? const Color(0xFFFF4D4D)
                                      : Theme.of(context).primaryColor)
                                  .withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2.seconds, color: Colors.white24)
                  .custom(
                    duration: 1500.ms,
                    builder: (context, value, child) => Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isMultiSelectMode
                                        ? const Color(0xFFFF4D4D)
                                        : Theme.of(context).primaryColor)
                                    .withOpacity(0.2 * value),
                            blurRadius: 20 * value,
                            spreadRadius: 5 * value,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isMultiSelectMode
                        ? '${_selectedScheduleIds.length} SELECTED'
                        : 'Automation Hub',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isMultiSelectMode
                        ? 'Manage selected items'
                        : 'Personalize your triggers',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFAAB0BC), // Cool Gray Label
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Rename Button (Restored)
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: _showRenameDialog,
              ),
              IconButton(
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white38,
                      size: 24,
                    ),
                    onPressed: _showHelpDialog,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 3.seconds,
                    curve: Curves.easeInOut,
                  ),
              if (_isMultiSelectMode)
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: const Color(0xFFFF4D4D), // Neon Red
                    size: 26,
                  ),
                  onPressed: _deleteSelected,
                ).animate().shake(duration: 500.ms)
              else
                IconButton(
                      icon: Icon(
                        Icons.select_all_rounded,
                        color: Colors.white.withOpacity(0.35),
                        size: 24,
                      ),
                      onPressed: () {
                        HapticService.selection();
                        setState(
                          () => _isMultiSelectMode = !_isMultiSelectMode,
                        );
                      },
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 2.5.seconds,
                      curve: Curves.easeInOut,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    HapticService.selection();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const _StaggeredHelpDialog(),
    );
  }

  void _showRenameDialog() {
    HapticService.selection();
    if (widget.initialDeviceId == null) return;

    final deviceId = widget.initialDeviceId!;
    final switches = ref.read(switchDevicesProvider);
    final device = switches.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => switches.first,
    );
    final controller = TextEditingController(text: device.name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF111111),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white12),
            ),
            title: Text(
              'Rename Device',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter new name',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await ref
                        .read(switchDevicesProvider.notifier)
                        .updateHardwareName(deviceId, controller.text.trim());
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSchedulesList() {
    final schedules = ref.watch(switchScheduleProvider);
    if (schedules.isEmpty) {
      return _buildEmptyState(
        FontAwesomeIcons.calendarXmark,
        'No active schedules',
      );
    }

    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 40),
        physics: const BouncingScrollPhysics(),
        itemExtent: 120, // Adjusted height for premium tile
        cacheExtent: 1000, // Pre-render items to prevent jank
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final s = schedules[index];
          final isSelected = _selectedScheduleIds.contains(s.id);
          // Always animate with staggering for a "breathing" feel on entrance
          return _animatedSection(
            index: index,
            ref: ref,
            child: _buildPremiumScheduleItem(s, isSelected),
          );
        },
      ),
    );
  }

  Widget _buildPremiumScheduleItem(SwitchSchedule s, bool isSelected) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // 12-hour format logic
    final hourInt = s.hour > 12 ? s.hour - 12 : (s.hour == 0 ? 12 : s.hour);
    final amPm = s.hour >= 12 ? 'PM' : 'AM';
    final timeStr =
        '${hourInt.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';

    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: () => _toggleMultiSelect(s.id),
        onTap: _isMultiSelectMode
            ? () => _toggleMultiSelect(s.id)
            : () => _showAddScheduleDialog(existingSchedule: s),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.15)
                : const Color(0xFF0A0A0A), // Solid OLED dark
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Icon(
                    FontAwesomeIcons.clock,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 20),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              timeStr,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: s.isEnabled
                                    ? Colors.white
                                    : Colors.white54,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            amPm,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: primaryColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (s.targetState
                                          ? primaryColor
                                          : Colors.redAccent)
                                      .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.targetState ? 'ON' : 'OFF',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: s.targetState
                                    ? primaryColor
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getNodeFriendlyName(s.targetNode)} • ${_getDaySummaryText(s.days)}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Action
                if (_isMultiSelectMode)
                  _buildSelectionCheck(isSelected)
                else
                  _BreathingToggle(
                    value: s.isEnabled,
                    onChanged: (v) {
                      ref
                          .read(switchScheduleProvider.notifier)
                          .updateSchedule(s.copyWith(isEnabled: v));
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDaySummaryText(List<int> days) {
    if (days.length == 7) return 'Every Day';
    if (days.isEmpty) return 'Never';
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  Widget _buildDaySummary(List<int> days) {
    if (days.length == 7)
      return Text(
        'Every Day',
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.white.withOpacity(0.45),
          fontWeight: FontWeight.w500,
        ),
      );
    if (days.isEmpty)
      return Text(
        'Never',
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.white.withOpacity(0.45),
          fontWeight: FontWeight.w500,
        ),
      );

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String summary = days.map((d) => dayNames[d - 1]).join(', ');
    return Flexible(
      child: Text(
        summary,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.white.withOpacity(0.45),
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSelectionCheck(bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? const Color(0xFFFF4D4D)
            : Colors.transparent, // Neon Red
        border: Border.all(
          color: isSelected ? const Color(0xFFFF4D4D) : Colors.white24,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 14,
        color: isSelected ? Colors.white : Colors.transparent,
      ),
    ).animate().scale();
  }

  String _getNodeFriendlyName(String node) {
    if (node == 'ecoMode') return 'ECO MODE';
    final switches = ref.read(switchDevicesProvider);
    final sw = switches.firstWhere(
      (s) => s.id == node,
      orElse: () => switches.first,
    );
    return (sw.nickname ?? sw.name).toUpperCase();
  }

  Widget _buildFooterButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, Responsive.paddingBottom + 20),
      child:
          Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticService.selection();
                    _showAddScheduleDialog();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                    ), // Adjust for border
                    child:
                        PixelLedBorder(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.tertiary,
                                Theme.of(context).primaryColor,
                              ],
                              borderRadius: 20,
                              strokeWidth: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Theme.of(context).primaryColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'CREATE NEW SCHEDULE',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 2500.ms, color: Colors.white12)
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.02, 1.02),
                              duration: 2.seconds,
                              curve: Curves.easeInOut,
                            ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 3.seconds,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
    );
  }

  void _showAddScheduleDialog({SwitchSchedule? existingSchedule}) async {
    await SchedulerService.requestPermissions();
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _AddScheduleSheet(
          schedule: existingSchedule,
          initialDeviceId: widget.initialDeviceId,
        ),
      );
    }
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.03), // Dynamic
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 54,
                  color: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.4), // Dynamic
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2.seconds,
              )
              .moveY(
                begin: 0,
                end: -5,
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 32),
          Text(
            message.toUpperCase(),
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.2),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2.5,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  // --- HELPER FOR ANIMATED SECTIONS ---
  Widget _animatedSection({
    required int index,
    required WidgetRef ref,
    required Widget child,
  }) {
    final animationsEnabled = ref
        .watch(animationSettingsProvider)
        .animationsEnabled;

    if (!animationsEnabled) return child;

    return child
        .animate()
        .fadeIn(
          delay: (index * 30).ms, // Faster stagger
          duration: 400.ms, // Snappier fade
          curve: Curves.easeOutQuad,
        )
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad);
  }
}

// Custom Sheet for Adding Schedule (Modified from original to fit new design)
class _AddScheduleSheet extends ConsumerStatefulWidget {
  final SwitchSchedule? schedule;
  final String? initialDeviceId;
  const _AddScheduleSheet({this.schedule, this.initialDeviceId});
  @override
  ConsumerState<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends ConsumerState<_AddScheduleSheet> {
  late TimeOfDay _selectedTime;
  late String _selectedNode;
  late bool _targetState;
  late List<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _selectedTime = TimeOfDay(
        hour: widget.schedule!.hour,
        minute: widget.schedule!.minute,
      );
      _selectedNode = widget.schedule!.targetNode;
      _targetState = widget.schedule!.targetState;
      _selectedDays = List.from(widget.schedule!.days);
    } else {
      _selectedTime = TimeOfDay.now();
      _selectedNode = widget.initialDeviceId ?? 'relay1';
      _targetState = true;
      _selectedDays = [1, 2, 3, 4, 5, 6, 7];
    }
  }

  @override
  Widget build(BuildContext context) {
    final switches = ref.watch(switchDevicesProvider);
    return _BaseSheet(
      title: widget.schedule != null ? 'EDIT SCHEDULE' : 'NEW SCHEDULE',
      onSave: () {
        final s = SwitchSchedule(
          id:
              widget.schedule?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          relayId: _selectedNode.startsWith('relay') ? _selectedNode : 'relay1',
          targetNode: _selectedNode,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          days: _selectedDays..sort(),
          targetState: _targetState,
          isEnabled:
              widget.schedule?.isEnabled ?? true, // Preserve enabled state
        );

        if (widget.schedule != null) {
          ref.read(switchScheduleProvider.notifier).updateSchedule(s);
        } else {
          ref.read(switchScheduleProvider.notifier).addSchedule(s);
        }

        Navigator.pop(context);
        HapticService.heavy();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.schedule != null ? 'Schedule Updated' : 'Schedule Created',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        children: [
          _buildTimePicker(),
          const SizedBox(height: 24),
          _buildNodeSelector(switches),
          const SizedBox(height: 24),
          _buildActionSelector(),
          const SizedBox(height: 24),
          _buildDaySelector(),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: false,
            initialDateTime: DateTime(
              2024,
              1,
              1,
              _selectedTime.hour,
              _selectedTime.minute,
            ),
            onDateTimeChanged: (dt) => setState(
              () => _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeSelector(List<dynamic> switches) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...switches.map(
            (s) => _NodePill(
              id: s.id,
              label: s.nickname ?? s.name,
              isSelected: _selectedNode == s.id,
              onTap: (v) => setState(() => _selectedNode = v),
            ),
          ),
          _NodePill(
            id: 'ecoMode',
            label: 'ECO MODE',
            isSelected: _selectedNode == 'ecoMode',
            onTap: (v) => setState(() => _selectedNode = v),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionPill(
              label: 'TURN ON',
              isSelected: _targetState == true,
              state: true,
              onTap: (v) => setState(() => _targetState = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              label: 'TURN OFF',
              isSelected: _targetState == false,
              state: false,
              onTap: (v) => setState(() => _targetState = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ACTIVE DAYS',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.6), // Contrast bump
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = i + 1;
              final active = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(
                    () => active
                        ? (_selectedDays.length > 1
                              ? _selectedDays.remove(day)
                              : null)
                        : _selectedDays.add(day),
                  );
                },
                child: AnimatedContainer(
                  duration: 250.ms,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Theme.of(context)
                              .primaryColor // Dynamic Theme
                        : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: active
                          ? Theme.of(context).primaryColor
                          : Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      days[i],
                      style: GoogleFonts.outfit(
                        color: active
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Geofence Sheet Deleted

// Common UI Components
class _BaseSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;

  const _BaseSheet({
    required this.title,
    required this.child,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child:
          RepaintBoundary(
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F14), // Deep Black
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 50,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                  child: Column(
                    children: [
                      _buildDragHandle()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.5, 1)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withOpacity(0.3),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ).animate().scaleY(
                            begin: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),
                          const SizedBox(width: 12),
                          Text(
                                title.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideX(begin: 0.1, end: 0),
                          const Spacer(),
                          IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 2.seconds,
                                curve: Curves.easeInOut,
                              ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: RepaintBoundary(
                            child: child
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 600.ms)
                                .moveY(begin: 20, end: 0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSaveButton(theme)
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutQuint,
                          ),
                    ],
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 700.ms,
                curve: Curves.easeOutQuart,
              )
              .fadeIn(),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                theme.primaryColor, // Dynamic Theme
                theme.primaryColor.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 10, // Moderate glow for button
                spreadRadius: -2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.transparent, // Glass effect managed by gradient
              ),
              child: InkWell(
                onTap: onSave,
                borderRadius: BorderRadius.circular(24),
                child: Center(
                  child:
                      Text(
                            'CONFIRM AUTOMATION',
                            style: GoogleFonts.outfit(
                              color:
                                  Colors.white, // Locked to white for contrast
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.02, 1.02),
                            duration: 1.seconds,
                            curve: Curves.easeInOut,
                          ),
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.1));
  }
}

class _NodePill extends StatelessWidget {
  final String id;
  final String label;
  final bool isSelected;
  final Function(String) onTap;

  const _NodePill({
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child:
          GestureDetector(
                onTap: () {
                  HapticService.selection();
                  onTap(id);
                },
                child: AnimatedContainer(
                  duration: 250.ms,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(
                            0.15,
                          ) // Dynamic Theme Glass
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.5)
                          : Colors.white.withOpacity(0.08),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
              .animate(target: isSelected ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool state;
  final Function(bool) onTap;

  const _ActionPill({
    required this.label,
    required this.isSelected,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = state == true
        ? Theme.of(context)
              .primaryColor // Dynamic Theme
        : const Color(0xFFFF4D4D); // Neon Red

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap(state);
      },
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withOpacity(0.1), blurRadius: 10)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// End of file helper classes removed as they are no longer used

// End of file helper classes removed as they are no longer used

// Breathing Toggle Switch
class _BreathingToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BreathingToggle({required this.value, required this.onChanged});

  @override
  State<_BreathingToggle> createState() => _BreathingToggleState();
}

class _BreathingToggleState extends State<_BreathingToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = Colors.white.withOpacity(0.1);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: () {
        HapticService.selection();
        widget.onChanged(!widget.value);
      },
      child: RepaintBoundary(
        child: AnimatedScale(
          scale: _isTapped ? 0.94 : 1.0,
          duration: 150.ms,
          curve: Curves.easeOutCirc,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 54,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: widget.value
                      ? (activeColor.computeLuminance() < 0.2
                            ? const Color(0xFF323236)
                            : activeColor)
                      : inactiveColor,
                  border: Border.all(
                    color: widget.value
                        ? activeColor.withOpacity(
                            0.4 + (_glowController.value * 0.3),
                          )
                        : Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: widget.value
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(
                              0.25 * _glowController.value,
                            ),
                            blurRadius: 12 * _glowController.value,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.value)
                      Positioned.fill(
                        child: Opacity(
                          opacity: _glowController.value * 0.2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.5),
                                  Colors.white.withOpacity(0),
                                ],
                                stops: const [0, 0.5, 1],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                transform: GradientRotation(
                                  _glowController.value * 6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                      left: widget.value ? 26.0 : 4.0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Widget to explain Beta status
// End of file helper classes removed as they are no longer used

// Helper for Staggered Animation
Widget _animatedSection({
  required int index,
  required WidgetRef ref,
  required Widget child,
}) {
  // Use AnimationProvider for staggering
  final delay = (index * 50).clamp(0, 500); // Cap delay
  return child
      .animate()
      .fadeIn(delay: delay.ms, duration: 400.ms)
      .slideX(begin: 0.1, end: 0, delay: delay.ms, curve: Curves.easeOut);
}

// Small chips for Days (Mon, Tue...) in the list tile
// End of file helper classes removed as they are no longer used

class _StaggeredHelpDialog extends StatelessWidget {
  const _StaggeredHelpDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = [
      {
        'q': 'How do schedules work?',
        'a':
            'Schedules trigger actions at specific times on selected days. They run locally on the ESP32 if configured, or via cloud.',
      },
      {
        'q': 'What is Geofencing?',
        'a':
            'Geofencing triggers actions when you enter or leave a defined location zone. It uses your phone\'s GPS/Location sensors.',
      },
      {
        'q': 'Are automations reliable?',
        'a':
            'Yes! Our Hybrid Engine ensures background precision. Make sure you grant background location permissions for Geofencing.',
      },
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22), // Unify background
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Automation Help',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(questions.length, (index) {
              return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questions[index]['q']!,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white, // Locked to white for contrast
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          questions[index]['a']!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withOpacity(
                              0.75,
                            ), // Contrast bump
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (300 + index * 100).ms)
                  .slideY(begin: 0.1, end: 0);
            }),
            const SizedBox(height: 8),
            GestureDetector(
                  onTap: () {
                    HapticService.light();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'GOT IT',
                        style: GoogleFonts.outfit(
                          color: (theme.primaryColor.computeLuminance() < 0.2
                              ? Colors.white
                              : theme.primaryColor),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 700.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 400.ms,
                ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
  }
}
