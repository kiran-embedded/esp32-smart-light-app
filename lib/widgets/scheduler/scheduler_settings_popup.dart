import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import '../../models/switch_schedule.dart';
import '../../models/geofence_rule.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/geofence_service.dart';
import '../../services/scheduler_service.dart';
import '../../core/ui/responsive_layout.dart';

class SchedulerSettingsPopup extends ConsumerStatefulWidget {
  const SchedulerSettingsPopup({super.key});

  @override
  ConsumerState<SchedulerSettingsPopup> createState() =>
      _SchedulerSettingsPopupState();
}

class _SchedulerSettingsPopupState extends ConsumerState<SchedulerSettingsPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _selectedScheduleIds = [];
  final List<String> _selectedGeofenceIds = [];
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleMultiSelect(String id, bool isGeofence) {
    setState(() {
      final list = isGeofence ? _selectedGeofenceIds : _selectedScheduleIds;
      if (list.contains(id)) {
        list.remove(id);
        if (_selectedScheduleIds.isEmpty && _selectedGeofenceIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        list.add(id);
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
    if (_selectedGeofenceIds.isNotEmpty) {
      ref.read(geofenceProvider.notifier).deleteRules(_selectedGeofenceIds);
      _selectedGeofenceIds.clear();
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
          color: const Color(0xFF1E1E22), // More Visible Graphite
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
            _buildTabBar(),
            Expanded(
              child: RepaintBoundary(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildSchedulesTab(), _buildGeofencingTab()],
                ),
              ),
            ),
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
    final theme = Theme.of(context);
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
                              ? Colors.redAccent
                              : theme.primaryColor,
                          (_isMultiSelectMode
                                  ? Colors.redAccent
                                  : theme.primaryColor)
                              .withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isMultiSelectMode
                                      ? Colors.redAccent
                                      : theme.primaryColor)
                                  .withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2.seconds, color: Colors.white24),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isMultiSelectMode
                        ? '${_selectedScheduleIds.length + _selectedGeofenceIds.length} SELECTED'
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
                      color: Colors.white.withOpacity(
                        0.65,
                      ), // Maximum contrast for secondary text
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
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
                    color: Colors.redAccent,
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

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.primaryColor.withOpacity(0.25),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.35),
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(text: 'Schedules'),
          Tab(text: 'Geofencing'),
        ],
        onTap: (index) {
          HapticService.light();
          setState(() {});
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSchedulesTab() {
    final schedules = ref.watch(switchScheduleProvider);
    if (schedules.isEmpty)
      return _buildEmptyState(
        FontAwesomeIcons.calendarXmark,
        'No active schedules',
      );

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 40),
      physics: const BouncingScrollPhysics(),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final s = schedules[index];
        final isSelected = _selectedScheduleIds.contains(s.id);
        return _animatedSection(
          index: index + 1,
          ref: ref,
          child: _buildScheduleItem(
            s,
            isSelected,
            index == schedules.length - 1,
          ),
        );
      },
    );
  }

  Widget _buildGeofencingTab() {
    final rules = ref.watch(geofenceProvider);
    if (rules.isEmpty)
      return _buildEmptyState(
        FontAwesomeIcons.locationDot,
        'No location zones',
      );

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 40),
      physics: const BouncingScrollPhysics(),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final r = rules[index];
        final isSelected = _selectedGeofenceIds.contains(r.id);
        return _animatedSection(
          index: index + 1,
          ref: ref,
          child: _buildGeofenceItem(r, isSelected, index == rules.length - 1),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.03),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 54,
                  color: theme.primaryColor.withOpacity(0.4),
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

  Widget _buildScheduleItem(SwitchSchedule s, bool isSelected, bool isLast) {
    final theme = Theme.of(context);
    final timeStr =
        '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
          onLongPress: () => _toggleMultiSelect(s.id, false),
          onTap: _isMultiSelectMode
              ? () => _toggleMultiSelect(s.id, false)
              : () => _showAddScheduleDialog(existingSchedule: s),
          child: AnimatedContainer(
            duration: 300.ms,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.redAccent.withOpacity(0.12)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Colors.redAccent.withOpacity(0.4)
                    : Colors.white.withOpacity(0.06),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.outfit(
                              fontSize: 34,
                              fontWeight: FontWeight.w300,
                              color: s.isEnabled
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.2),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (s.targetState
                                          ? theme.primaryColor
                                          : Colors.redAccent)
                                      .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    (s.targetState
                                            ? theme.primaryColor
                                            : Colors.redAccent)
                                        .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              s.targetState ? 'ON' : 'OFF',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: s.targetState
                                    ? (theme.primaryColor.computeLuminance() <
                                              0.2
                                          ? const Color(
                                              0xFF00FFC2,
                                            ) // Vibrant Mint
                                          : theme.primaryColor)
                                    : Colors.redAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _getNodeFriendlyName(s.targetNode),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: s.isEnabled
                                  ? Colors.white.withOpacity(0.95)
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDaySummary(s.days),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isMultiSelectMode)
                  _buildSelectionCheck(isSelected, theme)
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
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildGeofenceItem(GeofenceRule r, bool isSelected, bool isLast) {
    final theme = Theme.of(context);
    return GestureDetector(
          onLongPress: () => _toggleMultiSelect(r.id, true),
          onTap: _isMultiSelectMode
              ? () => _toggleMultiSelect(r.id, true)
              : () => _showAddGeofenceDialog(existingRule: r),
          child: AnimatedContainer(
            duration: 300.ms,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.redAccent.withOpacity(0.12)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Colors.redAccent.withOpacity(0.4)
                    : Colors.white.withOpacity(0.06),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                _buildAnimatedLocationIcon(r.isEnabled),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: r.isEnabled
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (r.triggerOnEnter
                                          ? const Color(0xFF00FFC2)
                                          : Colors.orangeAccent)
                                      .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    (r.triggerOnEnter
                                            ? const Color(0xFF00FFC2)
                                            : Colors.orangeAccent)
                                        .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              r.triggerOnEnter ? 'ENTER' : 'EXIT',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: r.triggerOnEnter
                                    ? const Color(0xFF00FFC2)
                                    : Colors.orangeAccent,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getNodeFriendlyName(r.targetNode),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isMultiSelectMode)
                  _buildSelectionCheck(isSelected, theme)
                else
                  _BreathingToggle(
                    value: r.isEnabled,
                    onChanged: (v) {
                      ref
                          .read(geofenceProvider.notifier)
                          .updateRule(r.copyWith(isEnabled: v));
                    },
                  ),
              ],
            ),
          ),
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildAnimatedLocationIcon(bool isEnabled) {
    final theme = Theme.of(context);
    final color = isEnabled
        ? theme.primaryColor
        : Colors.white.withOpacity(0.1);

    return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.15), width: 1),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isEnabled)
                  Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.primaryColor.withOpacity(0.1),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.8, 1.8),
                        duration: 1.5.seconds,
                        curve: Curves.easeOut,
                      )
                      .fadeOut(duration: 1.5.seconds),
                Icon(
                      Icons.location_on_rounded,
                      color: isEnabled ? theme.primaryColor : Colors.white24,
                      size: 22,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                      begin: 0,
                      end: -3,
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
        )
        .animate(target: isEnabled ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
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

  Widget _buildSelectionCheck(bool isSelected, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.redAccent : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.redAccent : Colors.white24,
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, Responsive.paddingBottom + 20),
      child:
          Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticService.selection();
                    _tabController.index == 0
                        ? _showAddScheduleDialog()
                        : _showAddGeofenceDialog();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: theme.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _tabController.index == 0
                              ? 'CREATE NEW SCHEDULE'
                              : 'ADD LOCATION ZONE',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 3.seconds,
                color: theme.primaryColor.withOpacity(0.1),
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
        builder: (context) => _AddScheduleSheet(schedule: existingSchedule),
      );
    }
  }

  void _showAddGeofenceDialog({GeofenceRule? existingRule}) async {
    final granted = await NebulaGeofenceService.requestPermissions();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Background Location Permission Required',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _AddGeofenceSheet(rule: existingRule),
      );
    }
  }
}

// Custom Sheet for Adding Schedule (Modified from original to fit new design)
class _AddScheduleSheet extends ConsumerStatefulWidget {
  final SwitchSchedule? schedule;
  const _AddScheduleSheet({this.schedule});
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
      _selectedNode = 'relay1';
      _targetState = true;
      _selectedDays = [1, 2, 3, 4, 5, 6, 7];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            backgroundColor: theme.primaryColor,
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
          _buildDaySelector(theme),
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
            use24hFormat: true,
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

  Widget _buildDaySelector(ThemeData theme) {
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
                        ? (theme.primaryColor.computeLuminance() < 0.2
                              ? const Color(0xFF323236)
                              : theme.primaryColor)
                        : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: active
                          ? theme.primaryColor
                          : Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.4),
                              blurRadius: 15,
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

// Geofencing sheet
class _AddGeofenceSheet extends ConsumerStatefulWidget {
  final GeofenceRule? rule;
  const _AddGeofenceSheet({this.rule});
  @override
  ConsumerState<_AddGeofenceSheet> createState() => _AddGeofenceSheetState();
}

class _AddGeofenceSheetState extends ConsumerState<_AddGeofenceSheet> {
  final _nameController = TextEditingController();
  ll.LatLng _selectedLocation = const ll.LatLng(0, 0);
  double _radius = 200.0;
  bool _triggerOnEnter = true;
  String _selectedNode = 'relay1';
  bool _targetState = true;
  TimeOfDay? _startTime;
  TimeOfDay? _stopTime;
  final MapController _mapController = MapController();
  bool _isGettingLocation = false;
  double? _accuracy;

  bool _isMapReady = false;
  bool _showNameError = false; // Validation State

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _nameController.text = widget.rule!.name;
      _selectedLocation = ll.LatLng(
        widget.rule!.latitude,
        widget.rule!.longitude,
      );
      _radius = widget.rule!.radius;
      _triggerOnEnter = widget.rule!.triggerOnEnter;
      _selectedNode = widget.rule!.targetNode;
      _targetState = widget.rule!.targetState;

      if (widget.rule!.startTime != null) {
        final parts = widget.rule!.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (widget.rule!.stopTime != null) {
        final parts = widget.rule!.stopTime!.split(':');
        _stopTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      // Delay map move slightly
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _isMapReady = true);
          _mapController.move(_selectedLocation, 16);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _isMapReady = true);
          _getCurrentLocation();
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _selectedLocation = ll.LatLng(p.latitude, p.longitude);
        _accuracy = p.accuracy;
        _isGettingLocation = false;
      });
      _mapController.move(_selectedLocation, 16);
    } catch (e) {
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final switches = ref.watch(switchDevicesProvider);
    return _BaseSheet(
      title: widget.rule != null ? 'EDIT ZONE' : 'LOCATION RULE',
      onSave: () {
        if (_nameController.text.trim().isEmpty) {
          setState(() => _showNameError = true);
          HapticService.light();
          return;
        }

        final r = GeofenceRule(
          id:
              widget.rule?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          radius: _radius,
          triggerOnEnter: _triggerOnEnter,
          triggerOnExit: !_triggerOnEnter,
          targetNode: _selectedNode,
          targetState: _targetState,
          startTime: _startTime != null
              ? '${_startTime!.hour}:${_startTime!.minute}'
              : null,
          stopTime: _stopTime != null
              ? '${_stopTime!.hour}:${_stopTime!.minute}'
              : null,
          isEnabled: widget.rule?.isEnabled ?? true,
        );

        if (widget.rule != null) {
          ref.read(geofenceProvider.notifier).updateRule(r);
        } else {
          ref.read(geofenceProvider.notifier).addRule(r);
        }

        Navigator.pop(context);
        HapticService.heavy();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.rule != null ? 'Zone Updated' : 'Zone Created',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            backgroundColor: theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapPreview(),
            const SizedBox(height: 20),
            _buildNameField(theme),
            if (_showNameError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  "Please enter a zone name",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn().shake(),
            ],
            const SizedBox(height: 20),
            _buildRadiusSelector(theme),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    label: 'ENTER ZONE',
                    isSelected: _triggerOnEnter,
                    state: true,
                    onTap: (v) => setState(() => _triggerOnEnter = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionPill(
                    label: 'EXIT ZONE',
                    isSelected: !_triggerOnEnter,
                    state: false,
                    onTap: (v) => setState(() => _triggerOnEnter = !v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNodeSelector(switches),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    label: 'TURN ON',
                    isSelected: _targetState == true,
                    state: true,
                    onTap: (v) => setState(() => _targetState = v),
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 24),
            _buildTimeConstraintSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15,
                onTap: (_, loc) => setState(() => _selectedLocation = loc),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation,
                      radius: _radius,
                      useRadiusInMeter: true,
                      color: theme.primaryColor.withOpacity(0.12),
                      borderColor: theme.primaryColor.withOpacity(0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 44,
                      height: 44,
                      child:
                          Icon(
                                Icons.location_on,
                                color: theme.primaryColor,
                                size: 40,
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .slideY(
                                begin: 0,
                                end: -0.15,
                                duration: 800.ms,
                                curve: Curves.easeInOut,
                              ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: _getCurrentLocation,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: _isGettingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.my_location,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                ),
              ),
            ),
            if (_accuracy != null && _accuracy! > 30)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'POOR SIGNAL (${_accuracy!.toStringAsFixed(0)}m)',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return TextField(
      controller: _nameController,
      style: GoogleFonts.outfit(color: theme.colorScheme.onSurface),
      decoration: _inputDecoration(theme, 'RULE NAME (e.g. HOME, OFFICE)'),
    );
  }

  Widget _buildRadiusSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ZONE RADIUS',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_radius.toInt()}m',
                  style: GoogleFonts.outfit(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: theme.primaryColor,
              inactiveTrackColor: Colors.white.withOpacity(0.05),
              thumbColor: Colors.white,
              overlayColor: theme.primaryColor.withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _radius,
              min: 100,
              max: 1000,
              divisions: 18,
              onChanged: (v) {
                HapticService.light();
                setState(() => _radius = v);
              },
            ),
          ),
        ],
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

  Widget _buildTimeConstraintSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 18,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              Text(
                'TIME WINDOW (OPTIONAL)',
                style: GoogleFonts.outfit(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'START',
                  time: _startTime,
                  onChanged: (v) => setState(() => _startTime = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white24,
                  size: 20,
                ),
              ),
              Expanded(
                child: _TimeButton(
                  label: 'STOP',
                  time: _stopTime,
                  onChanged: (v) => setState(() => _stopTime = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(ThemeData theme, String hint) {
  return InputDecoration(
    hintText: hint.toUpperCase(),
    hintStyle: GoogleFonts.outfit(
      color: Colors.white.withOpacity(0.15),
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
    filled: true,
    fillColor: Colors.white.withOpacity(0.04),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(
        color: theme.primaryColor.withOpacity(0.4),
        width: 1.5,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
  );
}

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
                    color: const Color(0xFF1E1E22),
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
                                  blurRadius: 12,
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
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: -2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: (theme.primaryColor.computeLuminance() < 0.2
                    ? const Color(0xFF323236)
                    : Colors.transparent),
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
    final theme = Theme.of(context);
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
                        ? (theme.primaryColor.computeLuminance() < 0.2
                              ? const Color(0xFF323236)
                              : theme.primaryColor.withOpacity(0.25))
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor.withOpacity(0.5)
                          : Colors.white.withOpacity(0.08),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.1),
                              blurRadius: 10,
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
        ? const Color(0xFF00FFC2)
        : Colors.orangeAccent;

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

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final Function(TimeOfDay) onChanged;

  const _TimeButton({required this.label, this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = time?.format(context) ?? '--:--';

    return GestureDetector(
      onTap: () async {
        HapticService.selection();
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: theme.primaryColor,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1E1E22), // Match graphite
                  onSurface: Colors.white,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          HapticService.medium();
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: GoogleFonts.outfit(
                color: time != null ? Colors.white : Colors.white10,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    const inactiveColor = Color(0xFF1C1C1E);

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
