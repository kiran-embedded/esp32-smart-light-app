import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/switch_device.dart';
import '../../providers/switch_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/persistence_service.dart';
import '../../core/ui/responsive_layout.dart';
import '../scheduler/scheduler_settings_popup.dart';
import 'icon_picker/icon_picker_dialog.dart';

class DeviceConfigPopup extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceConfigPopup({
    super.key,
    required this.deviceId,
  });

  @override
  ConsumerState<DeviceConfigPopup> createState() => _DeviceConfigPopupState();
}

class _DeviceConfigPopupState extends ConsumerState<DeviceConfigPopup> {
  bool _isFavorite = false;
  late String _deviceName;
  late SwitchDevice _device;
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isRenameSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  void _loadDeviceData() {
    final devices = ref.read(switchDevicesProvider);
    _device = devices.firstWhere((d) => d.id == widget.deviceId);
    _isFavorite = _device.isFavorite;
    _deviceName = _device.nickname ?? _device.name;
    _roomController.text = _device.room ?? '';
    _nicknameController.text = _device.nickname ?? _device.name;
  }

  @override
  void dispose() {
    _roomController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  int _getRelayIndex(String id) {
    final match = RegExp(r'\d+').firstMatch(id);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    // Watch switch state updates
    ref.listen<List<SwitchDevice>>(switchDevicesProvider, (prev, next) {
      final updatedDevice = next.firstWhere((d) => d.id == widget.deviceId);
      setState(() {
        _device = updatedDevice;
        _isFavorite = updatedDevice.isFavorite;
      });
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final bgColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    // Load active high/low logic state reactively from Firebase
    final deviceId = ref.read(switchDevicesProvider.notifier).currentDeviceId;
    final invertedLogicAsync = ref.watch(invertedLogicProvider(deviceId));
    final logicMap = invertedLogicAsync.valueOrNull ?? {};
    final relayIndex = _getRelayIndex(widget.deviceId);
    final isInverted = logicMap[relayIndex] ?? false;

    return Material(color: Colors.transparent, child: RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
            border: Border.all(
              color: activeColor.withOpacity(0.24),
              width: 0.8,
            ),
          ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Drag Handle bar
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _deviceName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Switch Hardware Configuration",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: isDark ? Colors.white38 : Colors.black38),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Divider(color: isDark ? Colors.white10 : Colors.black12),
          SizedBox(height: 16.h),

          // 1. Favorite Toggle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _isFavorite ? activeColor : (isDark ? Colors.white60 : Colors.black54),
                      size: 20.sp,
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Favorite Switch",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Display on Dashboard (Max 4)",
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isFavorite,
                  activeColor: activeColor,
                  onChanged: (value) async {
                    HapticService.selection();
                    final success = await ref.read(switchDevicesProvider.notifier).toggleFavorite(widget.deviceId);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Maximum limit of 4 favorite switches reached!",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          backgroundColor: activeColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // 2. Relay High/Low Logic Mode Selector
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: activeColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Relay Trigger Logic",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Toggle hardware active high/low mode",
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Segmented control block
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          HapticService.selection();
                          await ref.read(firebaseSwitchServiceProvider).updateInvertedLogic(
                            relayIndex,
                            false, // Active High (Standard)
                            deviceId: deviceId,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: !isInverted ? activeColor.withOpacity(0.12) : (isDark ? Colors.black26 : Colors.black.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: !isInverted ? activeColor : (isDark ? Colors.white10 : Colors.black12),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "ACTIVE HIGH\n(Standard)",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 9.sp,
                              color: !isInverted ? activeColor : textColor.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          HapticService.selection();
                          await ref.read(firebaseSwitchServiceProvider).updateInvertedLogic(
                            relayIndex,
                            true, // Active Low (Inverted)
                            deviceId: deviceId,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isInverted ? activeColor.withOpacity(0.12) : (isDark ? Colors.black26 : Colors.black.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isInverted ? activeColor : (isDark ? Colors.white10 : Colors.black12),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "ACTIVE LOW\n(Inverted)",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 9.sp,
                              color: isInverted ? activeColor : textColor.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ICON CONFIGURATION
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_rounded, color: activeColor, size: 20.sp),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Icon',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Choose an icon for this switch',
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => IconPickerDialog(
                        deviceId: widget.deviceId,
                        currentIconKey: _device.iconKey ?? '',
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Icon',
                          style: GoogleFonts.outfit(
                            color: textColor,
                            fontSize: 14.sp,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 14.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // RENAME SECTION
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_rounded, color: activeColor, size: 20.sp),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rename Device',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Set a custom name for this switch',
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _nicknameController,
                  style: GoogleFonts.outfit(color: textColor, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'Enter switch name',
                    hintStyle: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 12.sp),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: activeColor),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          HapticService.selection();
                          final newName = _nicknameController.text.trim();
                          if (newName.isEmpty) return;
                          setState(() => _isRenameSaving = true);
                          // Save nickname locally via PersistenceService
                          final nicknames = await PersistenceService.getNicknames();
                          nicknames[widget.deviceId] = newName;
                          await PersistenceService.saveNicknames(nicknames);
                          // Update provider state
                          await ref.read(switchDevicesProvider.notifier).updateNickname(widget.deviceId, newName);
                          setState(() {
                            _isRenameSaving = false;
                            _deviceName = newName;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Renamed locally!', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                              backgroundColor: activeColor,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: activeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: activeColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.smartphone_rounded, color: activeColor, size: 14.sp),
                              SizedBox(width: 6.w),
                              Text('Save Local', style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: activeColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          HapticService.selection();
                          final newName = _nicknameController.text.trim();
                          if (newName.isEmpty) return;
                          try {
                            final deviceId = ref.read(switchDevicesProvider.notifier).currentDeviceId;
                            await ref.read(firebaseSwitchServiceProvider).updateHardwareName(
                              widget.deviceId,
                              newName,
                              deviceId: deviceId,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Synced to Firebase!', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                                backgroundColor: activeColor,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Firebase sync failed', style: GoogleFonts.outfit(color: Colors.white)),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: activeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: activeColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_rounded, color: activeColor, size: 14.sp),
                              SizedBox(width: 6.w),
                              Text('Firebase', style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: activeColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // 3. Room / Folder Configuration
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      color: activeColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Room / Folder",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Group switches by room for easy access",
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _roomController,
                  style: GoogleFonts.outfit(color: textColor, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: "e.g. Bedroom, Kitchen, Living Room",
                    hintStyle: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 12.sp),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: activeColor),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(switchDevicesProvider.notifier).updateRoom(widget.deviceId, val);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // 4. Scheduler Route button
          GestureDetector(
            onTap: () {
              HapticService.selection();
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SchedulerSettingsPopup(
                  initialDeviceId: widget.deviceId,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_rounded, color: activeColor, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "Configure Switch Schedule",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white38 : Colors.black38, size: 12.sp),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 5. Save/Dismiss Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                elevation: 4,
              ),
              onPressed: () {
                HapticService.medium();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Relay logic configuration synced to Firebase cloud!",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    backgroundColor: activeColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                "CLOSE CONFIGURATION",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      ),
      ),
      ),
    );
  }
}

