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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0D11) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final accentColor = isDark ? Colors.greenAccent : const Color(0xFF00C853);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.code_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paste JSON',
                        style: TextStyle(
                          fontFamily: 'Outfit', // Uses GoogleFonts if defined globally, or standard
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Enter google-services.json content',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14171A) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 8,
                style: TextStyle(
                  fontFamily: 'FiraCode', // Monospace
                  fontSize: 12,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: '{\n  "project_info": {\n    "project_number": "123456789",\n    ...\n}',
                  hintStyle: TextStyle(
                    fontFamily: 'FiraCode',
                    fontSize: 12,
                    color: subtextColor.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _pasteFromClipboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.paste_rounded, size: 14, color: textColor),
                      const SizedBox(width: 6),
                      Text(
                        'Paste from Clipboard',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isValid
                        ? () {
                            final json = _jsonService.parseJsonString(
                              _textController.text.trim(),
                            );
                            Navigator.of(context).pop(json);
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isValid ? accentColor : isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isValid ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Import',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: _isValid ? Colors.black : subtextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
