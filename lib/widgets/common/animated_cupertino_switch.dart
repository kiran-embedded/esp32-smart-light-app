import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/performance_provider.dart';
import '../../services/haptic_service.dart';

class AnimatedCupertinoSwitch extends ConsumerStatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AnimatedCupertinoSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  ConsumerState<AnimatedCupertinoSwitch> createState() =>
      _AnimatedCupertinoSwitchState();
}

class _AnimatedCupertinoSwitchState
    extends ConsumerState<AnimatedCupertinoSwitch> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPerfMode = ref.watch(performanceProvider);

    final child = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (widget.value && !isPerfMode)
            BoxShadow(
              color: (widget.activeColor ?? theme.colorScheme.primary)
                  .withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: CupertinoSwitch(
        value: widget.value,
        activeColor: widget.activeColor ?? theme.colorScheme.primary,
        onChanged: (val) {
          if (widget.onChanged != null) {
            HapticService.light();
            widget.onChanged!(val);
          }
        },
      ),
    );

    if (isPerfMode) return child;

    return Animate(
      key: ValueKey(widget.value),
      effects: [
        ScaleEffect(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 150.ms,
          curve: Curves.easeOutBack,
        ),
      ],
      child: child,
    );
  }
}
