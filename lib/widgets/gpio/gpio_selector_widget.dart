import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class GpioSelectorWidget extends StatefulWidget {
  final int selectedPin;
  final ValueChanged<int> onPinSelected;

  const GpioSelectorWidget({
    super.key,
    required this.selectedPin,
    required this.onPinSelected,
  });

  @override
  State<GpioSelectorWidget> createState() => _GpioSelectorWidgetState();
}

class _GpioSelectorWidgetState extends State<GpioSelectorWidget> {
  late int _selectedPin;

  @override
  void initState() {
    super.initState();
    _selectedPin = widget.selectedPin;
  }

  Color _getPinColor(int pin) {
    if (AppConstants.unsafeGpioPins.contains(pin)) {
      return Colors.red.shade300;
    } else if (AppConstants.cautionGpioPins.contains(pin)) {
      return Colors.orange.shade300;
    } else if (AppConstants.safeGpioPins.contains(pin)) {
      return Colors.green.shade300;
    }
    return Colors.grey.shade400;
  }

  IconData _getPinIcon(int pin) {
    if (AppConstants.unsafeGpioPins.contains(pin)) {
      return Icons.dangerous;
    } else if (AppConstants.cautionGpioPins.contains(pin)) {
      return Icons.warning_amber;
    } else if (AppConstants.safeGpioPins.contains(pin)) {
      return Icons.check_circle;
    }
    return Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Select GPIO Pin',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Green = Safe, Yellow = Caution, Red = Avoid',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected pin display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getPinColor(_selectedPin).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getPinColor(_selectedPin), width: 2),
          ),
          child: Row(
            children: [
              Icon(
                _getPinIcon(_selectedPin),
                color: _getPinColor(_selectedPin),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPIO $_selectedPin',
                      style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (AppConstants.gpioPinDescriptions.containsKey(
                      _selectedPin,
                    ))
                      Text(
                        AppConstants.gpioPinDescriptions[_selectedPin]!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pin grid selector
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Safe pins
                ...AppConstants.safeGpioPins.map((pin) => _buildPinChip(pin)),
                // Caution pins
                ...AppConstants.cautionGpioPins.map(
                  (pin) => _buildPinChip(pin),
                ),
                // Unsafe pins (show but discourage)
                ...AppConstants.unsafeGpioPins.map((pin) => _buildPinChip(pin)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('Safe', Colors.green.shade300, Icons.check_circle),
            _buildLegendItem(
              'Caution',
              Colors.orange.shade300,
              Icons.warning_amber,
            ),
            _buildLegendItem('Avoid', Colors.red.shade300, Icons.dangerous),
          ],
        ),
      ],
    );
  }

  Widget _buildPinChip(int pin) {
    final isSelected = pin == _selectedPin;
    final color = _getPinColor(pin);
    final isUnsafe = AppConstants.unsafeGpioPins.contains(pin);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPin = pin;
        });
        widget.onPinSelected(pin);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pin.toString(),
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (isUnsafe)
              Icon(
                Icons.block,
                size: 12,
                color: isSelected ? Colors.white : Colors.red.shade700,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
