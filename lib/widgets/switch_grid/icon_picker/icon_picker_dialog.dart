import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/haptic_service.dart';
import '../../../../providers/switch_provider.dart';
import '../../../../core/utils/app_icons.dart';

class IconPickerDialog extends ConsumerWidget {
  final String deviceId;
  final String currentIconKey;

  const IconPickerDialog({
    super.key,
    required this.deviceId,
    required this.currentIconKey,
  });

  // Icons now provided by AppIcons in core/utils/app_icons.dart

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final bgColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).padding.bottom + 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border.all(
            color: activeColor.withOpacity(0.24),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SELECT ICON",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Choose an icon for this device",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
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
            const SizedBox(height: 20),
            
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: AppIcons.availableIcons.length,
                itemBuilder: (context, index) {
                  final entry = AppIcons.availableIcons.entries.elementAt(index);
                  final isSelected = entry.key == currentIconKey;
                  
                  return GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      ref.read(switchDevicesProvider.notifier).updateIconKey(deviceId, entry.key);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? activeColor.withOpacity(0.15) 
                            : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? activeColor 
                              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected ? activeColor : (isDark ? Colors.accents[index % Colors.accents.length] : Colors.black54),
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
