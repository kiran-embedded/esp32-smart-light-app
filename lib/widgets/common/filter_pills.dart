import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterPills extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color activeColor;

  const FilterPills({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = selectedIndex == index;
          
          return GestureDetector(
            onTap: () => onSelected(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? activeColor 
                      : (isDark ? const Color(0xFF333333) : const Color(0xFFD1D1D6)),
                  width: 1,
                ),
              ),
              child: Text(
                options[index],
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
