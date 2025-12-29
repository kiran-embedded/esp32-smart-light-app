import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/restart_widget.dart';

class RebootScreen extends StatefulWidget {
  const RebootScreen({super.key});

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
    "ENTERING NEBULA...",
    "SYSTEM OPTIMIZED.",
  ];

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() {
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_step < _sequence.length) {
        setState(() {
          _logs.add(_sequence[_step]);
        });
        _step++;
      } else {
        timer.cancel();
        // Trigger actual restart
        Future.delayed(const Duration(milliseconds: 500), () {
          RestartWidget.restartApp(context);
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "> $log",
                    style: GoogleFonts.shareTechMono(
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (_step < _sequence.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
