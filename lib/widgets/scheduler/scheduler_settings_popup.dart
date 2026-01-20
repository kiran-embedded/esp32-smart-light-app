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
import '../../core/ui/animation_engine.dart';

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
          color: const Color(0xFF0A0A0A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
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
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _isMultiSelectMode
                      ? Colors.redAccent
                      : theme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isMultiSelectMode
                                  ? Colors.redAccent
                                  : theme.primaryColor)
                              .withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Text(
                    _isMultiSelectMode
                        ? '${_selectedScheduleIds.length + _selectedGeofenceIds.length} SELECTED'
                        : 'AUTOMATION HUB',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  if (!_isMultiSelectMode) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        "BETA TEST",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              onPressed: _deleteSelected,
            )
          else
            IconButton(
              icon: Icon(
                Icons.select_all_rounded,
                color: Colors.white.withOpacity(0.3),
              ),
              onPressed: () {
                HapticService.selection();
                setState(() => _isMultiSelectMode = !_isMultiSelectMode);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3.0, color: theme.primaryColor),
          borderRadius: BorderRadius.circular(2),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.3),
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
        tabs: const [
          Tab(text: 'SCHEDULES'),
          Tab(text: 'GEOFENCING'),
        ],
        onTap: (index) => setState(() {}),
      ),
    );
  }

  Widget _buildSchedulesTab() {
    final schedules = ref.watch(switchScheduleProvider);
    if (schedules.isEmpty)
      return _buildEmptyState(FontAwesomeIcons.calendarXmark, 'NO SCHEDULES');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        const _BetaInfoCard(
          description:
              "Our ultra-reliable background engine ensures your schedules trigger with millisecond precision, even when the app is completely closed.",
        ),
        const _PremiumSectionHeader(title: 'Active Schedules'),
        _PremiumGroupedContainer(
          children: List.generate(schedules.length, (index) {
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
          }),
        ),
      ],
    );
  }

  Widget _buildGeofencingTab() {
    final rules = ref.watch(geofenceProvider);
    if (rules.isEmpty)
      return _buildEmptyState(FontAwesomeIcons.locationDot, 'NO GEOFENCES');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        const _BetaInfoCard(
          description:
              "Geofencing uses proximity sensors and GPS to trigger actions automatically. Background reliability depends on OS location permissions.",
        ),
        const _PremiumSectionHeader(title: 'Geofence Rules'),
        _PremiumGroupedContainer(
          children: List.generate(rules.length, (index) {
            final r = rules[index];
            final isSelected = _selectedGeofenceIds.contains(r.id);
            return _animatedSection(
              index: index + 1,
              ref: ref,
              child: _buildGeofenceItem(
                r,
                isSelected,
                index == rules.length - 1,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: theme.primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
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
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: _buildPremiumSettingTile(
          context,
          title: timeStr,
          subtitle: _getNodeFriendlyName(s.targetNode),
          extraSubtitle: _buildDayChips(s.days),
          leading: _buildPremiumIcon(
            Icons.access_time_filled_rounded,
            s.targetState ? theme.primaryColor : Colors.redAccent,
            isAnimating: s.isEnabled,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isMultiSelectMode)
                const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white24,
                        size: 16,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.3, end: 0.8, duration: 2.seconds),
              if (_isMultiSelectMode) _buildSelectionCheck(isSelected, theme),
              if (!_isMultiSelectMode)
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
          isLast: isLast,
        ),
      ),
    );
  }

  Widget _buildGeofenceItem(GeofenceRule r, bool isSelected, bool isLast) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: () => _toggleMultiSelect(r.id, true),
      onTap: _isMultiSelectMode
          ? () => _toggleMultiSelect(r.id, true)
          : () => _showAddGeofenceDialog(existingRule: r),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: _buildPremiumSettingTile(
          context,
          title: r.name.toUpperCase(),
          subtitle:
              '${r.triggerOnEnter ? 'ENTER' : 'EXIT'} • ${_getNodeFriendlyName(r.targetNode)}',
          leading: _buildPremiumIcon(
            Icons.location_on_rounded,
            const Color(0xFFFF8A80), // Vibrant Light Red (Neon-ish)
            isAnimating: r.isEnabled,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isMultiSelectMode)
                const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white24,
                        size: 16,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.3, end: 0.8, duration: 2.seconds),
              if (_isMultiSelectMode) _buildSelectionCheck(isSelected, theme),
              if (!_isMultiSelectMode)
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
          isLast: isLast,
        ),
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
        const SnackBar(
          content: Text('Background Location Permission Required'),
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
    return SizedBox(
      height: 120,
      child: CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
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
    );
  }

  Widget _buildNodeSelector(List<dynamic> switches) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...switches.map(
            (s) => _NodePill(
              s.id,
              s.nickname ?? s.name,
              _selectedNode == s.id,
              (v) => setState(() => _selectedNode = v),
            ),
          ),
          _NodePill(
            'ecoMode',
            'ECO MODE',
            _selectedNode == 'ecoMode',
            (v) => setState(() => _selectedNode = v),
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
              'TURN ON',
              _targetState == true,
              true,
              (v) => setState(() => _targetState = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              'TURN OFF',
              _targetState == false,
              false,
              (v) => setState(() => _targetState = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(ThemeData theme) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? const Color(0xFF007AFF) // Deep iOS-style blue
                    : Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: active
                      ? const Color(0xFF007AFF)
                      : Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  days[i],
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
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
                    'ENTER ZONE',
                    _triggerOnEnter,
                    true,
                    (v) => setState(() => _triggerOnEnter = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionPill(
                    'EXIT ZONE',
                    !_triggerOnEnter,
                    false,
                    (v) => setState(() => _triggerOnEnter = !v),
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
                    'TURN ON',
                    _targetState == true,
                    true,
                    (v) => setState(() => _targetState = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionPill(
                    'TURN OFF',
                    _targetState == false,
                    false,
                    (v) => setState(() => _targetState = v),
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
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                      color: theme.primaryColor.withOpacity(0.1),
                      borderColor: theme.primaryColor,
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child:
                          Icon(
                                Icons.location_on,
                                color: theme.primaryColor,
                                size: 40,
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .slideY(
                                begin: 0,
                                end: -0.2,
                                duration: 1.seconds,
                                curve: Curves.easeInOut,
                              ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _getCurrentLocation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isGettingLocation
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
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
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'POOR SIGNAL (${_accuracy!.toStringAsFixed(0)}m)',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RADIUS',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_radius.toInt()} METERS',
              style: GoogleFonts.outfit(
                color: theme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _radius,
          min: 100,
          max: 1000,
          divisions: 18,
          activeColor: theme.primaryColor,
          inactiveColor: theme.dividerColor,
          onChanged: (v) => setState(() => _radius = v),
        ),
      ],
    );
  }

  Widget _buildNodeSelector(List<dynamic> switches) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...switches.map(
            (s) => _NodePill(
              s.id,
              s.nickname ?? s.name,
              _selectedNode == s.id,
              (v) => setState(() => _selectedNode = v),
            ),
          ),
          _NodePill(
            'ecoMode',
            'ECO MODE',
            _selectedNode == 'ecoMode',
            (v) => setState(() => _selectedNode = v),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeConstraintSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'TIME CONSTRAINT (OPTIONAL)',
                style: GoogleFonts.outfit(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimeButton(
                'START',
                _startTime,
                (v) => setState(() => _startTime = v),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: theme.dividerColor,
                size: 16,
              ),
              _TimeButton(
                'STOP',
                _stopTime,
                (v) => setState(() => _stopTime = v),
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
      color: Colors.white.withOpacity(0.2),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    ),
    filled: true,
    fillColor: Colors.black.withOpacity(0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: theme.primaryColor.withOpacity(0.5),
        width: 1.5,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: [
                _buildDragHandle(),
                const SizedBox(height: 24),
                Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: AnimationEngine.appleEase)
                    .slideX(
                      begin: -0.1,
                      end: 0,
                      curve: AnimationEngine.iosSpring,
                    ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: child.animate().fadeIn(
                      delay: 200.ms,
                      duration: 400.ms,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSaveButton(theme),
              ],
            ),
          ).animate().slideY(
            begin: 0.2,
            end: 0,
            duration: 600.ms,
            curve: AnimationEngine.iosSpring,
          ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSave,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'CONFIRM AUTOMATION',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 3.seconds,
          color: theme.primaryColor.withOpacity(0.1),
        );
  }
}

class _NodePill extends StatelessWidget {
  final String id;
  final String name;
  final bool isSelected;
  final Function(String) onTap;

  const _NodePill(this.id, this.name, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Text(
          name.toUpperCase(),
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool state;
  final Function(bool) onTap;

  const _ActionPill(this.label, this.isSelected, this.state, this.onTap);

  @override
  Widget build(BuildContext context) {
    // High contrast colors: Green for ON, Red for OFF
    final activeColor = state == true
        ? const Color(0xFF00FF88)
        : const Color(0xFFFF3D00);
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap(state);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.15),
            width: 2.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: activeColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.5,
                ),
              ),
            ],
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

  const _TimeButton(this.label, this.time, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) {
          HapticService.medium();
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.orangeAccent.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time == null
                  ? '--:--'
                  : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.outfit(
                color: time == null
                    ? Colors.white.withOpacity(0.2)
                    : Colors.deepOrangeAccent,
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

// --- PREMIUM UI COMPONENTS (MARRYING SETTINGS SCREEN DESIGN) ---

class _PremiumSectionHeader extends StatelessWidget {
  final String title;
  const _PremiumSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumGroupedContainer extends ConsumerWidget {
  final List<Widget> children;
  const _PremiumGroupedContainer({required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }
}

Widget _buildPremiumSettingTile(
  BuildContext context, {
  required String title,
  required String subtitle,
  Widget? extraSubtitle,
  required Widget leading,
  required Widget trailing,
  bool isLast = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
    ),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold, // Bolder title
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),
              if (extraSubtitle != null) ...[
                const SizedBox(height: 6),
                extraSubtitle,
              ],
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

Widget _buildPremiumIcon(
  IconData icon,
  Color color, {
  bool isAnimating = false,
}) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withOpacity(0.15), // Highly transparent background
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2), width: 1.5),
    ),
    child: Center(
      child: Icon(icon, color: color, size: 22)
          .animate(target: isAnimating ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 1.seconds,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.1, 1.1),
            end: const Offset(1, 1),
            duration: 1.seconds,
            curve: Curves.easeInOut,
          ),
    ),
  );
}

// Breathing Toggle Switch
class _BreathingToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BreathingToggle({required this.value, required this.onChanged});

  @override
  State<_BreathingToggle> createState() => _BreathingToggleState();
}

class _BreathingToggleState extends State<_BreathingToggle> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = Colors.white.withOpacity(0.1);

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.value ? activeColor : inactiveColor,
          boxShadow: widget.value
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              left: widget.value ? 24.0 : 2.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
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
}

// Widget to explain Beta status
class _BetaInfoCard extends StatelessWidget {
  final String description;
  const _BetaInfoCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5), // Slate-like dark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            FontAwesomeIcons.circleInfo,
            size: 16,
            color: Colors.blueGrey.shade300,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.outfit(
                color: Colors.blueGrey.shade200,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
Widget _buildDayChips(List<int> days) {
  if (days.length == 7) {
    return Text(
      'EVERY DAY',
      style: GoogleFonts.outfit(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return Wrap(
    spacing: 4,
    children: days.map((d) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          dayNames[d - 1].toUpperCase(),
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList(),
  );
}
