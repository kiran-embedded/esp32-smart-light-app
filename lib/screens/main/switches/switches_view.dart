import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/common/aurexa_app_bar.dart';
import '../../../widgets/switch_grid/switch_list_card.dart';
import '../../../providers/switch_provider.dart';
import '../../../providers/live_info_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/haptic_service.dart';

class SwitchesView extends ConsumerStatefulWidget {
  const SwitchesView({super.key});

  @override
  ConsumerState<SwitchesView> createState() => _SwitchesViewState();
}

class _SwitchesViewState extends ConsumerState<SwitchesView> {
  int _filterIndex = 0;
  String _searchQuery = '';
  String? _selectedRoom;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _uniqueRooms(List devices) {
    final rooms = devices
        .map((d) => d.room?.trim())
        .whereType<String>()
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return rooms;
  }

  List _filteredDevices(List allDevices) {
    var devices = allDevices;

    if (_filterIndex == 1) {
      devices = devices.where((d) => d.isFavorite).toList();
    } else if (_filterIndex == 2 && _selectedRoom != null) {
      devices =
          devices.where((d) => d.room?.trim() == _selectedRoom).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      devices = devices.where((d) {
        final name = d.name.toLowerCase();
        final room = (d.room ?? '').toLowerCase();
        return name.contains(q) || room.contains(q);
      }).toList();
    }

    return devices;
  }

  Future<void> _pickRoom(List<String> rooms) async {
    if (rooms.isEmpty) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Room',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              ...rooms.map(
                (room) => ListTile(
                  title: Text(
                    room,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: _selectedRoom == room
                      ? const Icon(Icons.check_rounded, color: AppTheme.neonGreen)
                      : null,
                  onTap: () => Navigator.pop(context, room),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _filterIndex = 2;
        _selectedRoom = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allDevices = ref.watch(switchDevicesProvider);
    final devices = _filteredDevices(allDevices);
    final rooms = _uniqueRooms(allDevices);

    final espOnline = allDevices.any((d) => d.isConnected);
    final onlineCount = allDevices.where((d) => d.isConnected).length;
    final offlineCount = allDevices.length - onlineCount;

    return Column(
      children: [
        AurexaAppBar(
          actions: [
            GestureDetector(
              onTap: () {
                HapticService.heavy();
                _showAddOptionsPopup(context, isDark);
              },
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
                    _SearchBar(
                      isDark: isDark,
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    SizedBox(height: gap),
                    _FilterRow(
                      isDark: isDark,
                      selectedIndex: _filterIndex,
                      selectedRoom: _selectedRoom,
                      rooms: rooms,
                      onAll: () => setState(() {
                        _filterIndex = 0;
                        _selectedRoom = null;
                      }),
                      onFavorites: () => setState(() {
                        _filterIndex = 1;
                        _selectedRoom = null;
                      }),
                      onRoom: (room) => setState(() {
                        _filterIndex = 2;
                        _selectedRoom = room;
                      }),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      child: devices.isEmpty
                          ? Center(
                              child: Text(
                                'No switches found',
                                style: GoogleFonts.outfit(
                                  color: isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: _filterIndex == 0 ? _uniqueRooms(devices).length + (devices.any((d) => d.room?.trim().isEmpty ?? true) ? 1 : 0) : 1,
                              itemBuilder: (context, index) {
                                // Group logic
                                Map<String, List> grouped = {};
                                if (_filterIndex == 0) {
                                  for (var d in devices) {
                                    final r = d.room?.trim().isNotEmpty == true ? d.room!.trim() : 'Unassigned';
                                    grouped.putIfAbsent(r, () => []).add(d);
                                  }
                                } else {
                                  grouped['Switches'] = devices;
                                }
                                
                                final keys = grouped.keys.toList()..sort();
                                final roomName = keys[index];
                                final roomDevices = grouped[roomName]!;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_filterIndex == 0)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 12, left: 4),
                                          child: Row(
                                            children: [
                                              Icon(
                                                roomName == 'Unassigned' ? Icons.device_unknown_rounded : Icons.door_front_door_rounded,
                                                color: AppTheme.neonGreen,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                roomName.toUpperCase(),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: isDark ? Colors.white10 : Colors.black12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ...roomDevices.map((d) {
                                        final deviceIndex = allDevices.indexOf(d);
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: SizedBox(
                                            height: 72, // fixed height for list cards
                                            child: SwitchListCard(
                                              device: d,
                                              isDark: isDark,
                                              accent: AppTheme.switchAccentPalette[
                                                  deviceIndex % AppTheme.switchAccentPalette.length],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: gap),
                    _StatusSummaryBar(
                      isDark: isDark,
                      totalDevices: allDevices.length,
                      onlineCount: onlineCount,
                      offlineCount: offlineCount,
                      espOnline: espOnline,
                    ),
                    SizedBox(height: gap * 0.5),
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

class _SearchBar extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.isDark,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5EA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white30 : Colors.black38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search switches...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Icon(
            Icons.tune_rounded,
            color: isDark ? Colors.white30 : Colors.black38,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final String? selectedRoom;
  final List<String> rooms;
  final VoidCallback onAll;
  final VoidCallback onFavorites;
  final Function(String) onRoom;

  const _FilterRow({
    required this.isDark,
    required this.selectedIndex,
    required this.selectedRoom,
    required this.rooms,
    required this.onAll,
    required this.onFavorites,
    required this.onRoom,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterPill(
            label: 'All',
            icon: Icons.grid_view_rounded,
            isSelected: selectedIndex == 0,
            isDark: isDark,
            useGradient: true,
            onTap: onAll,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Favorites',
            icon: Icons.favorite_rounded,
            isSelected: selectedIndex == 1,
            isDark: isDark,
            onTap: onFavorites,
          ),
          ...rooms.map((room) {
            final isSelected = selectedIndex == 2 && selectedRoom == room;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterPill(
                label: room,
                icon: Icons.home_rounded,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => onRoom(room),
              ),
            );
          }),
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
  final bool showChevron;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    this.useGradient = false,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = isSelected && useGradient;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFD1D1D6);
    final textColor = active
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);
    final iconColor = active
        ? Colors.white
        : (isDark ? Colors.white54 : Colors.black54);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      color: AppTheme.neonGreen.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: iconColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSummaryBar extends StatelessWidget {
  final bool isDark;
  final int totalDevices;
  final int onlineCount;
  final int offlineCount;
  final bool espOnline;

  const _StatusSummaryBar({
    required this.isDark,
    required this.totalDevices,
    required this.onlineCount,
    required this.offlineCount,
    required this.espOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFE8E8ED),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppTheme.neonGreen,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalDevices Devices',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '$onlineCount Online · $offlineCount Offline',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFE8E8ED),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: (espOnline ? AppTheme.neonGreen : AppTheme.accentRed)
                        .withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_rounded,
                    color: espOnline ? AppTheme.neonGreen : AppTheme.accentRed,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESP32',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        espOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color:
                              espOnline ? AppTheme.neonGreen : AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

  void _showAddOptionsPopup(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF222222) : const Color(0xFFE8E8ED),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: AppTheme.neonGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'Expand your smart home',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            _buildPopupOption(
              context: context,
              isDark: isDark,
              title: 'Add New Switch',
              subtitle: 'Configure a new ESP32 smart switch',
              icon: Icons.power_rounded,
              color: AppTheme.neonGreen,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Switch provisioning requires MDNS setup.',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              },
            ),
            _buildPopupOption(
              context: context,
              isDark: isDark,
              title: 'Create Room Space',
              subtitle: 'Organize switches into a new room',
              icon: Icons.meeting_room_rounded,
              color: AppTheme.accentBlue,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Room created successfully.',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    backgroundColor: AppTheme.accentBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupOption({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEBEBEF),
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }
