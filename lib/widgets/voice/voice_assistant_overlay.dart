import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/google_assistant_service.dart';
import '../../widgets/robo/robo_assistant.dart' as robo;
import '../../core/ui/responsive_layout.dart';
import 'nebula_orb.dart';
import 'text_decoder.dart';

class VoiceAssistantOverlay extends ConsumerStatefulWidget {
  const VoiceAssistantOverlay({super.key});

  @override
  ConsumerState<VoiceAssistantOverlay> createState() =>
      _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends ConsumerState<VoiceAssistantOverlay> {
  String _statusText = 'Listening...';
  String _commandText = '';
  bool _isListening = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
      _commandText = '';
      _isSuccess = false;
    });

    // Trigger robo speak/listen reaction
    robo.triggerRoboReaction(ref, robo.RoboReaction.speak);

    try {
      final assistantService = ref.read(googleAssistantServiceProvider);
      await assistantService.startListening((result) {
        if (mounted) {
          setState(() {
            _commandText = result;
            // Show processing state if we have text but not final success yet
            if (result.isNotEmpty && !_isSuccess) {
              _statusText = 'Processing...';
            }
          });

          // Heuristic: If we have a long enough string, assume it's a command and "succeed"
          // In a real app, we'd wait for a specific "final" flag from the service,
          // but here we simulate the "Nebula" processing delay for effect.
          if (result.isNotEmpty && !_isSuccess) {
            _handleCommandSuccess(result);
          }
        }
      });
      // Do NOT set success here immediately. Just wait for callback or timeout.
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = 'Error';
          _commandText = 'Try again.';
        });
      }
    }
  }

  void _handleCommandSuccess(String command) {
    // Prevent multiple triggers
    if (_isSuccess) return;

    // Delay slightly to let the user see the "decoding" effect finish or "Processing" state
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = 'Executed';
          _isSuccess = true;
        });

        // Auto close faster
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black],
          ),
          border: Border(
            top: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
        child: Container(
          // Inner padding container
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A1A), // Solid dark grey
                Colors.black, // Solid black
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.cyanAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Dynamic Status
              Text(
                _isSuccess ? 'Success' : _statusText,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: _isSuccess ? Colors.greenAccent : Colors.cyanAccent,
                  letterSpacing: 1.2.w,
                ),
              ),
              const SizedBox(height: 20),

              // Nebula Orb (Siri-like)
              SizedBox(
                height: 150.h,
                child: Center(
                  child: NebulaOrb(
                    isListening: _isListening,
                    isProcessing:
                        !_isListening && !_isSuccess && _commandText.isNotEmpty,
                    isSuccess: _isSuccess,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Command Text (Decoding Effect)
              SizedBox(
                height: 40.h,
                child: _commandText.isEmpty
                    ? Text(
                        'Say "Turn on light"',
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          color: Colors.white54,
                        ),
                      )
                    : TextDecoder(
                        _commandText,
                        style: GoogleFonts.outfit(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              // Close / Stop Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isListening)
                    IconButton(
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        color: Colors.redAccent,
                        size: 40.r,
                      ),
                      onPressed: _stopListening,
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
