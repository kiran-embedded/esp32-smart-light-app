import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceVisualizer extends StatelessWidget {
  final bool isListening;
  const VoiceVisualizer({super.key, required this.isListening});

  @override
  Widget build(BuildContext context) {
    // Generate 5 bars for the wave
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        // Staggered delays for wave effect
        final heightBase = 20.0 + (index % 3) * 15.0; // Variant heights

        return Container(
              width: 8,
              height: isListening
                  ? heightBase
                  : 8, // Flatten when not listening
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            )
            .animate(
              target: isListening ? 1 : 0,
              onPlay: (c) => c.repeat(reverse: true),
            )
            .scaleY(
              begin: 0.3,
              end: 1.5,
              duration: Duration(milliseconds: 500 + (index * 50)),
              curve: Curves.easeInOut,
            ) // Dynamic height scaling
            .tint(
              color: Colors.purpleAccent,
              duration: const Duration(seconds: 2),
            ); // Subtle color shift
      }),
    );
  }
}
