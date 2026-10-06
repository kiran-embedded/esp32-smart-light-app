import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/restart_widget.dart';

class RebootScreen extends StatefulWidget {
  final Future<bool> authFuture;
  const RebootScreen({super.key, required this.authFuture});

  @override
  State<RebootScreen> createState() => _RebootScreenState();
}

class _RebootScreenState extends State<RebootScreen> {
  final List<String> _logs = [];
  Timer? _timer;
  int _step = 0;

  final List<String> _sequence = [
    "INITIATING SYSTEM REBOOT...",
    "CLEARING CACHE MEMORY...",
    "ESTABLISHING SECURE LINK...",
    "AUTHENTICATING USER...",
    "ENTERING AUREXA...",
    "SYSTEM OPTIMIZED.",
  ];

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() {
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {
      if (_step < _sequence.length) {
        if (_step == 3) {
          // Pause animation to wait for authentication
          timer.cancel();
          setState(() {
            _logs.add(_sequence[_step]);
          });
          _step++;
          
          try {
            bool success = await widget.authFuture;
            if (success) {
              if (mounted) _startSequence();
            } else {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          } catch(e) {
            if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
            }
          }
          return;
        }

        setState(() {
          _logs.add(_sequence[_step]);
        });
        _step++;
      } else {
        timer.cancel();
        // Gracefully pop the reboot screen to reveal the MainScreen underneath
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cyberpunk/Terminal Style
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._logs.map(
                (log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "> ",
                        style: GoogleFonts.shareTechMono(
                          color: Colors.greenAccent.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        log,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.greenAccent,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              color: Colors.greenAccent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
                ),
              ),
              if (_step < _sequence.length)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 16.0),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
