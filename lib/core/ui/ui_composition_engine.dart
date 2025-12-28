import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'dart:ui';

/// UI COMPOSITION ENGINE
/// Core rendering optimization layer. Do not modify.
/// UI COMPOSITION ENGINE (Refactored to Footer)
class CopyrightFooter extends StatelessWidget {
  const CopyrightFooter({super.key});

  // Obfuscated: https://github.com/kiran-embedded/esp32-smart-light-app
  final List<int> _s = const [
    104,
    116,
    116,
    112,
    115,
    58,
    47,
    47,
    103,
    105,
    116,
    104,
    117,
    98,
    46,
    99,
    111,
    109,
    47,
    107,
    105,
    114,
    97,
    110,
    45,
    101,
    109,
    98,
    101,
    100,
    100,
    101,
    100,
    47,
    101,
    115,
    112,
    51,
    50,
    45,
    115,
    109,
    97,
    114,
    116,
    45,
    108,
    105,
    103,
    104,
    116,
    45,
    97,
    112,
    112,
  ];

  // Obfuscated: "Kiran Embedded"
  final List<int> _l = const [
    75,
    105,
    114,
    97,
    110,
    32,
    69,
    109,
    98,
    101,
    100,
    100,
    101,
    100,
  ];

  String get _u => utf8.decode(_s);
  String get _t => utf8.decode(_l);

  void _v() async {
    final u = Uri.parse(_u);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _v,
            borderRadius: BorderRadius.circular(30),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F).withOpacity(
                  0.6,
                ), // Increased opacity slightly since blur is gone
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copyright_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '2025 $_t', // "2025 Kiran Embedded"
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 10,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 6),
                  const FaIcon(
                    FontAwesomeIcons.github,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
