import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/haptic_service.dart';
import '../../providers/switch_provider.dart';
import '../../widgets/switch_grid/switch_grid.dart';
import '../../widgets/scheduling/new_schedule_sheet.dart';

class ControlView extends ConsumerStatefulWidget {
  const ControlView({super.key});

  @override
  ConsumerState<ControlView> createState() => _ControlViewState();
}

class _ControlViewState extends ConsumerState<ControlView> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(switchDevicesProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    // Build room filter list
    final Set<String> rooms = {'All', 'Favorites'};
    for (var d in devices) {
      if (d.room != null && d.room!.isNotEmpty) rooms.add(d.room!);
    }
    final roomList = rooms.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: topPadding + 16),

        // ─── HEADER ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AUREXA ',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'CORE',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF00FF66),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'SMART • SIMPLE • CONNECTED',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
              // Add Timer shortcut
              GestureDetector(
                onTap: () {
                  HapticService.selection();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const NewScheduleSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF00FF66).withOpacity(0.4),
                        width: 1.2),
                    color: const Color(0xFF00FF66).withOpacity(0.06),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF00FF66), size: 22),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── SEARCH BAR ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _searchQuery.isNotEmpty
                    ? const Color(0xFF00FF66).withOpacity(0.4)
                    : Colors.white.withOpacity(0.07),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search switches...',
                hintStyle: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(0.3), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white.withOpacity(0.4), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ─── FILTER PILLS (hidden while searching) ───
        if (_searchQuery.isEmpty) ...[
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: roomList.length,
              itemBuilder: (context, index) {
                final room = roomList[index];
                final isActive = _selectedFilter == room;
                return GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _selectedFilter = room);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF00FF66).withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF00FF66).withOpacity(0.5)
                            : Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      room,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: isActive
                            ? const Color(0xFF00FF66)
                            : Colors.white.withOpacity(0.4),
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ─── SWITCH GRID ───
        Expanded(
          child: SwitchGrid(
            filterRoom: _searchQuery.isNotEmpty ? 'All' : _selectedFilter,
            searchQuery: _searchQuery,
          ),
        ),
      ],
    );
  }
}
