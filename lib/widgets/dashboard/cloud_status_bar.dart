import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'solid_panel_container.dart';
import '../../services/connectivity_service.dart';

class CloudStatusBar extends ConsumerWidget {
  const CloudStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final connectivity = ref.watch(connectivityProvider);
    
    final isConnected = connectivity.isFirebaseConnected;
    final statusText = isConnected ? 'Connected' : 'Disconnected';
    final statusColor = isConnected ? primary : Colors.redAccent;

    return SolidPanelContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      borderRadius: 16.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: statusColor,
                size: 28
              ),
              const SizedBox(width: 24),
              Text(
                'CLOUD MODE',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 20,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 24),
              Text(
                statusText,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }
}
