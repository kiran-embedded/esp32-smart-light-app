import 'package:flutter/material.dart';
import 'frosted_glass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/google_assistant_service.dart';
import '../../widgets/robo/robo_assistant.dart' as robo;

class GoogleAssistantDialog extends ConsumerStatefulWidget {
  const GoogleAssistantDialog({super.key});

  @override
  ConsumerState<GoogleAssistantDialog> createState() =>
      _GoogleAssistantDialogState();
}

class _GoogleAssistantDialogState extends ConsumerState<GoogleAssistantDialog> {
  String _lastCommand = '';
  bool _isListening = false;

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _lastCommand = '';
    });

    // Trigger robo speak reaction
    robo.triggerRoboReaction(ref, robo.RoboReaction.speak);

    try {
      final assistantService = ref.read(googleAssistantServiceProvider);
      await assistantService.startListening((result) {
        setState(() {
          _lastCommand = result;
          _isListening = false;
        });
      });
    } catch (e) {
      setState(() {
        _isListening = false;
        _lastCommand = 'Error: $e';
      });
    }
  }

  Future<void> _stopListening() async {
    final assistantService = ref.read(googleAssistantServiceProvider);
    await assistantService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedGlass(
        padding: const EdgeInsets.all(24),
        radius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Google Assistant', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            // Listening indicator
            if (_isListening)
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withOpacity(0.2),
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 40,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Listening...', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Say: "Turn on living room light"',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Column(
                children: [
                  Icon(
                    Icons.mic_none,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  if (_lastCommand.isNotEmpty) ...[
                    Text('Last command:', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lastCommand,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            const SizedBox(height: 24),
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isListening)
                  ElevatedButton.icon(
                    onPressed: _stopListening,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _startListening,
                    icon: const Icon(Icons.mic),
                    label: const Text('Start Listening'),
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
