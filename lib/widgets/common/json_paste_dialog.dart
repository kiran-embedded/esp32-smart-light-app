import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/json_import_service.dart';
import '../common/frosted_glass.dart';

class JsonPasteDialog extends StatefulWidget {
  const JsonPasteDialog({super.key});

  @override
  State<JsonPasteDialog> createState() => _JsonPasteDialogState();
}

class _JsonPasteDialogState extends State<JsonPasteDialog> {
  final _textController = TextEditingController();
  final _jsonService = JsonImportService();
  bool _isValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_validateJson);
  }

  void _validateJson() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isValid = false;
        _errorMessage = null;
      });
      return;
    }

    try {
      final json = _jsonService.parseJsonString(text);
      if (json == null) {
        setState(() {
          _isValid = false;
          _errorMessage = 'Invalid JSON format';
        });
        return;
      }
      final isValid = _jsonService.validateGoogleServicesJson(json);
      setState(() {
        _isValid = isValid;
        _errorMessage = isValid ? null : 'Invalid google-services.json format';
      });
    } catch (e) {
      setState(() {
        _isValid = false;
        _errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _textController.text = clipboardData!.text!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedGlass(
        padding: const EdgeInsets.all(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste JSON', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      hintText:
                          'Paste your google-services.json content here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste from Clipboard'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValid
                      ? () {
                          final json = _jsonService.parseJsonString(
                            _textController.text.trim(),
                          );
                          Navigator.of(context).pop(json);
                        }
                      : null,
                  child: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
