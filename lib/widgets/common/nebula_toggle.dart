import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/haptic_service.dart';

class NebulaToggle extends ConsumerStatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;
  final Color? activeColor;

  const NebulaToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 50.0,
    this.height = 28.0,
    this.activeColor,
  });

  @override
  ConsumerState<NebulaToggle> createState() => _NebulaToggleState();
}

class _NebulaToggleState extends ConsumerState<NebulaToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _position = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    // Color tween defined in build to access theme/widget props
    if (widget.value) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(NebulaToggle oldWidget) {
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
    final theme = Theme.of(context);
    final activeCol = widget.activeColor ?? theme.colorScheme.primary;

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
          final t = _position.value; // 0.0 to 1.0

          return Container(
            width: widget.width,
            height: widget.height,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track
                Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    color: Color.lerp(
                      Colors.black.withOpacity(0.4),
                      activeCol.withOpacity(0.15),
                      t,
                    ),
                    border: Border.all(
                      color: Color.lerp(
                        Colors.white.withOpacity(0.1),
                        activeCol.withOpacity(0.5),
                        t,
                      )!,
                      width: 1.5,
                    ),
                    boxShadow: const [],
                  ),
                ),

                // Thumb
                Transform.translate(
                  offset: Offset(
                    (widget.width - widget.height) * t + 2, // +2 padding
                    0,
                  ),
                  child: Container(
                    width: widget.height - 4,
                    height: widget.height - 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(Colors.grey.shade400, Colors.white, t)!,
                          Color.lerp(Colors.grey.shade600, activeCol, t)!,
                        ],
                      ),
                      boxShadow: const [],
                    ),
                    child: Center(
                      child: Container(
                        width: (widget.height - 4) * 0.3,
                        height: (widget.height - 4) * 0.3,
                        decoration: BoxDecoration(
                          color: t > 0.5 ? activeCol : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: const [],
                        ),
                      ),
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
