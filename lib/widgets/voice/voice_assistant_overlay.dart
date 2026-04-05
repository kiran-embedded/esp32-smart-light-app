import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/google_assistant_service.dart';
import '../../widgets/robo/robo_assistant.dart' as robo;
import '../../core/ui/responsive_layout.dart';
import 'quantum_voice_orb.dart';
import 'text_decoder.dart';

class VoiceAssistantOverlay extends ConsumerStatefulWidget {
  const VoiceAssistantOverlay({super.key});

  @override
  ConsumerState<VoiceAssistantOverlay> createState() =>
      _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends ConsumerState<VoiceAssistantOverlay>
    with SingleTickerProviderStateMixin {
  String _statusText = 'Listening...';
  String _commandText = '';
  bool _isListening = false;
  bool _isSuccess = false;
  bool _hasPopped = false;

  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _slideController.forward();
    _startListening();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
      _commandText = '';
      _isSuccess = false;
    });

    robo.triggerRoboReaction(ref, robo.RoboReaction.speak);

    try {
      final assistantService = ref.read(googleAssistantServiceProvider);
      await assistantService.startListening((result, isFinal) {
        if (mounted) {
          setState(() {
            _commandText = result;
            if (result.isNotEmpty && !isFinal) {
              _statusText = 'Decoding...';
            }
          });

          if (isFinal && result.isNotEmpty && !_isSuccess) {
            _handleCommandSuccess(result);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = 'Error';
          _commandText = 'Permission or limit reached.';
        });
      }
    }
  }

  void _handleCommandSuccess(String command) {
    if (_isSuccess) return;

    setState(() {
      _isListening = false;
      _statusText = 'PROCESSED';
      _isSuccess = true;
    });

    // Final cooldown before popping
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_hasPopped) {
        _slideController.reverse().then((_) {
          if (mounted) {
            _hasPopped = true;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        });
      }
    });
  }

  Future<void> _stopListening() async {
    final assistantService = ref.read(googleAssistantServiceProvider);
    await assistantService.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
        _statusText = 'Stopped';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          // Liquid Slide-up Container
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                final slideY = (1.0 - _slideController.value) * 300;
                final opacity = _slideController.value;

                return Transform.translate(
                  offset: Offset(0, slideY),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.85),
                            Colors.black,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(24, 40, 24, 60.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status + Glitter Orb
                          Text(
                            _statusText.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: _isSuccess
                                  ? Colors.greenAccent
                                  : Colors.cyanAccent.withOpacity(0.7),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            height: 120.h,
                            child: QuantumVoiceOrb(
                              isListening: _isListening,
                              isProcessing:
                                  !_isListening &&
                                  !_isSuccess &&
                                  _commandText.isNotEmpty,
                              isSuccess: _isSuccess,
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextDecoder(
                            _commandText.isEmpty
                                ? 'NEBULA READY...'
                                : _commandText,
                            style: GoogleFonts.outfit(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 32),

                          if (_isListening)
                            IconButton(
                              onPressed: _stopListening,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
