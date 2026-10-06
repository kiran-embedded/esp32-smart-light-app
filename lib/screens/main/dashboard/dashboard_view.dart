import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/dashboard/app_header.dart';
import '../../../widgets/dashboard/time_greeting_card.dart';
import '../../../widgets/dashboard/system_status_card.dart';
import '../../../widgets/dashboard/quick_access_row.dart';
import '../../../core/system/display_config.dart';
import '../../../widgets/voice/voice_assistant_overlay.dart';
import '../../../widgets/common/frosted_glass.dart';
import '../../../widgets/dashboard/quick_controls_grid.dart';
import '../../../providers/google_home_provider.dart';
import '../../../providers/switch_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  void _showGoogleHomeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final googleHomeLinked = ref.watch(googleHomeLinkedProvider).valueOrNull ?? false;
          final service = ref.read(googleHomeServiceProvider);
          final theme = Theme.of(context);

          return Dialog(
            backgroundColor: Colors.transparent,
            child: FrostedGlass(
              padding: const EdgeInsets.all(24),
              radius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Google Home',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 24.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    googleHomeLinked
                        ? 'Google Home is linked. Your devices are synced to the cloud.'
                        : 'Google Home is not linked. Link it to sync devices across platforms.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (googleHomeLinked)
                        TextButton(
                          onPressed: () async {
                            await service.unlinkGoogleHome();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: const Text('Unlink'),
                        ),
                      if (!googleHomeLinked)
                        ElevatedButton(
                          onPressed: () async {
                            await service.linkGoogleHome();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: const Text('Link'),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check favorites count to determine scrolling behavior
    final devices = ref.watch(switchDevicesProvider);
    final favoriteCount = devices.where((d) => d.isFavorite).length;
    final bool scrollLock = favoriteCount <= 2;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by AppBackground
      body: SafeArea(
        child: SingleChildScrollView(
          physics: scrollLock ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(),
              const SizedBox(height: 24),
              const TimeGreetingCard(),
              const SizedBox(height: 16),
              const SystemStatusCard(),
              const SizedBox(height: 16),
              const QuickControlsGrid(),
              const SizedBox(height: 24),
              QuickAccessRow(
                onGoogleHomeTap: () => _showGoogleHomeDialog(context, ref),
                onAssistantTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const VoiceAssistantOverlay(),
                  );
                },
              ),
              const SizedBox(height: 100), // Padding for bottom nav bar
            ],
          ),
        ),
      ),
    );
  }
}
