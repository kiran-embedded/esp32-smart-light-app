import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../providers/security_provider.dart';
import '../../services/sound_service.dart';
import '../../services/voice_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/security/nebula_bot.dart';

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
  Timer? _snoozeTimer;
  bool _isSnoozed = false;
  double _dragPosition = 0;
  final double _sliderWidth = 280;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSirenAndVoice();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-dismiss if alarm is cleared or system disarmed remotely
  }

  void _startSirenAndVoice() {
    if (_isSnoozed) return;

    final soundService = ref.read(soundServiceProvider);
    soundService.playAlarmHigh();

    _triggerTTS();
    _ttsTimer?.cancel();
    _ttsTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _triggerTTS();
    });
  }

  void _triggerTTS() {
    if (_isSnoozed) return;

    final state = ref.read(securityProvider);
    final triggeredList = state.triggeredSensors.map((sid) {
      final nickname = state.sensors[sid]?.nickname;
      return (nickname ?? sid).replaceAll("PIR", "P.I.R");
    }).toList();

    String text;
    if (triggeredList.isEmpty) {
      text = "${widget.zone} motion detected";
    } else if (triggeredList.length == 1) {
      text = "${triggeredList.first} motion detected";
    } else {
      text = "Multiple zones breached: ${triggeredList.join(", ")}";
    }

    ref.read(voiceServiceProvider).speak(text);
  }

  void _snooze() {
    HapticService.medium();
    setState(() {
      _isSnoozed = true;
    });

    ref.read(soundServiceProvider).stopAlarm();
    ref.read(voiceServiceProvider).stop();
    _ttsTimer?.cancel();

    _snoozeTimer?.cancel();
    _snoozeTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() => _isSnoozed = false);
        _startSirenAndVoice();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ttsTimer?.cancel();
    _snoozeTimer?.cancel();
    super.dispose();
  }

  void _stopAlarm() {
    HapticService.heavy();
    ref.read(soundServiceProvider).stopAlarm();
    ref.read(voiceServiceProvider).stop();
    ref.read(securityProvider.notifier).stopAlarm();
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss logic: if alarm stopped or system disarmed
    ref.listen(securityProvider, (previous, next) {
      if (!next.isArmed ||
          (!next.isAlarmActive && (previous?.isAlarmActive ?? false))) {
        if (mounted) {
          ref.read(soundServiceProvider).stopAlarm();
          ref.read(voiceServiceProvider).stop();
          Navigator.of(context).pop();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      (_isSnoozed
                              ? Colors.amberAccent
                              : Theme.of(context).colorScheme.error)
                          .withOpacity(0.12 * _pulseController.value),
                      Colors.black,
                    ],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Mascot
                NebulaBotWidget(isAlarmActive: !_isSnoozed),

                const SizedBox(height: 40),

                // Alert Title
                Text(
                      _isSnoozed ? "SNOOZED" : "ALARM ACTIVE",
                      style: GoogleFonts.outfit(
                        color: _isSnoozed
                            ? Colors.amberAccent
                            : Colors.redAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 2.seconds)
                    .shake(duration: 500.ms, hz: 4),

                const SizedBox(height: 8),

                const SizedBox(height: 8),

                Consumer(
                  builder: (context, ref, _) {
                    final securityState = ref.watch(securityProvider);
                    final breaches = securityState.activeBreaches;

                    if (breaches.isEmpty) {
                      return Text(
                        "${widget.zone.toUpperCase()} TRIGGERED",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 220),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: breaches.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      color: Colors.white10,
                                      height: 20,
                                    ),
                                itemBuilder: (context, index) {
                                  final b = breaches[index];
                                  final sensorId =
                                      b['sensor'] as String? ?? 'Unknown';
                                  final nickname =
                                      securityState.sensors[sensorId]?.nickname;
                                  final sensorName =
                                      nickname ?? sensorId.toUpperCase();
                                  final ts = b['timestamp'] as num? ?? 0;
                                  final date =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        (ts * 1000).toInt(),
                                      );
                                  final timeStr = DateFormat(
                                    'HH:mm:ss',
                                  ).format(date);

                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(
                                            0.2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sensorName,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              "BREACH DETECTED",
                                              style: GoogleFonts.outfit(
                                                color: Colors.redAccent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white24,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                        if (breaches.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              "MULTIPLE ZONES COMPROMISED",
                              style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ).animate(onPlay: (c) => c.repeat()).shimmer(),
                          ),
                      ],
                    );
                  },
                ),

                const Spacer(),

                // PIN / SLIDER AREA
                if (!_isSnoozed) ...[
                  _buildSlideToStop(),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _snooze,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        "SNOOZE (5 MIN)",
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Snooze indicator
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amberAccent.withOpacity(0.5),
                    ),
                    strokeWidth: 2,
                  ).animate(onPlay: (c) => c.repeat()).rotate(),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _stopAlarm,
                    child: Text(
                      "STOP PERMANENTLY",
                      style: TextStyle(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideToStop() {
    return Container(
      width: _sliderWidth,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              "SWIPE TO STOP",
              style: GoogleFonts.outfit(
                color: Colors.redAccent.withOpacity(0.4),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
          ),
          Positioned(
            left: _dragPosition,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition += details.delta.dx;
                  _dragPosition = _dragPosition.clamp(0.0, _sliderWidth - 70);
                });
                if (_dragPosition >= _sliderWidth - 80) {
                  _stopAlarm();
                }
              },
              onHorizontalDragEnd: (details) {
                if (_dragPosition < _sliderWidth - 80) {
                  setState(() => _dragPosition = 0);
                }
              },
              child: Container(
                width: 66,
                height: 66,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent,
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
