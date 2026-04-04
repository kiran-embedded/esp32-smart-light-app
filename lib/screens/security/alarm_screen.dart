import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/security_provider.dart';
import '../../services/sound_service.dart';
import '../../services/voice_service.dart';
import '../../services/haptic_service.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  final String zone;

  const AlarmScreen({super.key, required this.zone});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _ttsTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initial Sound & Voice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSirenAndVoice();
    });
  }

  void _startSirenAndVoice() {
    final soundService = ref.read(soundServiceProvider);
    final voiceService = ref.read(voiceServiceProvider);

    // Play high alarm (should be looping in sound service)
    soundService.playAlarmHigh();
    voiceService.stop(); // Pre-emptive stop if anything is playing

    // Trigger TTS every 7 seconds
    _triggerTTS();
    _ttsTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _triggerTTS();
    });
  }

  void _triggerTTS() {
    ref.read(voiceServiceProvider).speak("${widget.zone} motion detected");
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ttsTimer?.cancel();
    super.dispose();
  }

  void _stopAlarm() {
    HapticService.heavy();
    // Stop sound
    // ref.read(soundServiceProvider).stopAll(); // Add this to sound service

    // Acknowledge in Firebase
    ref.read(securityProvider.notifier).acknowledge(widget.zone);

    // Exit activity
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.redAccent.withOpacity(0.15 * _pulseController.value),
                  Colors.black,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Warning Icon
              Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 100,
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(0.8, 0.8),
                    duration: 800.ms,
                  ),

              const SizedBox(height: 40),

              // Title
              Text(
                "MOTION DETECTED",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.redAccent.withOpacity(0.8),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 10),

              // Zone Subtext
              Text(
                "${widget.zone.toUpperCase()} ZONE",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ).animate().fade(delay: 300.ms, duration: 500.ms),

              const Spacer(),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlBtn(
                    icon: Icons.snooze_rounded,
                    label: "SNOOZE",
                    color: Colors.white24,
                    onTap: () {
                      HapticService.light();
                      // Logic for snooze could go here
                    },
                  ),
                  _buildControlBtn(
                    icon: Icons.stop_rounded,
                    label: "STOP",
                    color: Colors.redAccent,
                    onTap: _stopAlarm,
                    isPrimary: true,
                  ),
                ],
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                if (isPrimary)
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
