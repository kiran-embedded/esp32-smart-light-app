import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class TextDecoder extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const TextDecoder(
    this.text, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<TextDecoder> createState() => _TextDecoderState();
}

class _TextDecoderState extends State<TextDecoder> {
  String _displayedText = '';
  Timer? _timer;
  final _random = Random();
  final String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';

  @override
  void initState() {
    super.initState();
    _startDecoding();
  }

  @override
  void didUpdateWidget(TextDecoder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startDecoding();
    }
  }

  void _startDecoding() {
    _timer?.cancel();
    final totalSteps = widget.text.length * 3; // Number of scramble steps
    int step = 0;

    // If text is empty or very short, just show it
    if (widget.text.isEmpty) {
      setState(() => _displayedText = '');
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      step++;

      // Calculate how many characters should be "finalized"
      final progress = step / totalSteps;
      final visibleChars = (widget.text.length * progress).floor();

      if (visibleChars >= widget.text.length) {
        setState(() => _displayedText = widget.text);
        timer.cancel();
        return;
      }

      final buffer = StringBuffer();

      // Add finalized characters
      buffer.write(widget.text.substring(0, visibleChars));

      // Add scrambled characters for the rest
      for (int i = visibleChars; i < widget.text.length; i++) {
        if (widget.text[i] == ' ') {
          buffer.write(' ');
        } else {
          buffer.write(_chars[_random.nextInt(_chars.length)]);
        }
      }

      setState(() => _displayedText = buffer.toString());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      textAlign: TextAlign.center,
    );
  }
}
