import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/haptic_service.dart';
import '../../core/theme/app_theme.dart';

class AurexaToggle extends ConsumerStatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;
  final Color? activeColor;

  const AurexaToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 46.0,
    this.height = 26.0,
    this.activeColor,
  });

  @override
  ConsumerState<AurexaToggle> createState() => _AurexaToggleState();
}

class _AurexaToggleState extends ConsumerState<AurexaToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _position = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (widget.value) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AurexaToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCol = widget.activeColor ?? AppTheme.neonGreen;

    return GestureDetector(
      onTap: () {
        if (widget.onChanged != null) {
          HapticService.toggle(!widget.value);
          widget.onChanged!(!widget.value);
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _position.value;
          final thumbSize = widget.height - 4;
          final travel = widget.width - widget.height;

          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    gradient: t > 0.01
                        ? LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color.lerp(
                                isDark
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFE5E5EA),
                                const Color(0xFF69F0AE),
                                t,
                              )!,
                              Color.lerp(
                                isDark
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFE5E5EA),
                                activeCol,
                                t,
                              )!,
                            ],
                          )
                        : null,
                    color: t <= 0.01
                        ? (isDark
                            ? const Color(0xFF333333)
                            : const Color(0xFFE5E5EA))
                        : null,
                    boxShadow: t > 0.5
                        ? [
                            BoxShadow(
                              color: activeCol.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
                Transform.translate(
                  offset: Offset(2 + travel * t, 0),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
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
    );
  }
}
