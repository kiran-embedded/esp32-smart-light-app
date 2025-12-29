import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sound_service.dart';
import '../../widgets/robo/robo_assistant.dart';
import '../../widgets/robo/robo_assistant.dart' as robo;
import '../../widgets/live_info/time_date_widget.dart';
import '../../widgets/live_info/status_card.dart';
import '../../widgets/switch_grid/switch_grid.dart';
import '../../services/google_assistant_service.dart';
import '../../providers/google_home_provider.dart';
import '../../providers/live_info_provider.dart';
import '../../widgets/common/google_assistant_dialog.dart';
import '../../widgets/common/frosted_glass.dart';
import '../../widgets/common/pixel_led_border.dart';
import '../settings/settings_screen.dart';
import '../../widgets/navigation/animated_nav_icon.dart'; // Added
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      robo.triggerRoboReaction(ref, robo.RoboReaction.wakeUp);
      // Delayed check to ensure audio engine is ready and user interaction context is set
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(soundServiceProvider).playStartup();
      });
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onBottomNavTapped(int index) {
    if (_currentPage != index) {
      ref.read(soundServiceProvider).playTabSwitch();
    }
    setState(() {
      _currentPage = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastLinearToSlowEaseIn, // iOS-like friction/spring feel
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(theme)
          .animate()
          .fadeIn(delay: 400.ms, duration: 400.ms)
          .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: const [DashboardView(), ControlView(), SettingsScreen()],
        ),
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: ClipRect(
        child: RepaintBoundary(
          // Cache the blur
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), // Unified blur
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: BottomNavigationBar(
                currentIndex: _currentPage,
                onTap: _onBottomNavTapped,
                backgroundColor: Colors.transparent,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: Colors.white.withOpacity(0.3),
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: const AnimatedNavIcon(
                      icon: Icons.dashboard_rounded,
                      isSelected: false,
                      label: 'DASHBOARD',
                    ),
                    activeIcon: const AnimatedNavIcon(
                      icon: Icons.dashboard_rounded,
                      isSelected: true,
                      label: 'DASHBOARD',
                    ),
                    label: 'DASHBOARD',
                  ),
                  BottomNavigationBarItem(
                    icon: const AnimatedNavIcon(
                      icon: Icons.grid_view_rounded,
                      isSelected: false,
                      label: 'SWITCHES',
                    ),
                    activeIcon: const AnimatedNavIcon(
                      icon: Icons.grid_view_rounded,
                      isSelected: true,
                      label: 'SWITCHES',
                    ),
                    label: 'SWITCHES',
                  ),
                  BottomNavigationBarItem(
                    icon: const AnimatedNavIcon(
                      icon: Icons.settings_suggest_rounded,
                      isSelected: false,
                      label: 'SETTINGS',
                    ),
                    activeIcon: const AnimatedNavIcon(
                      icon: Icons.settings_suggest_rounded,
                      isSelected: true,
                      label: 'SETTINGS',
                    ),
                    label: 'SETTINGS',
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

// ---- EXTRACTED WIDGETS TO PREVENT LAG ----

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final liveInfo = ref.watch(liveInfoProvider);
    final systemState = liveInfo.acVoltage > 0
        ? "Power Active\nProtection On"
        : "System Standby\nWaiting for Power";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 120.0, top: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                        children: [
                          Text(
                            'NEBULA',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: theme.colorScheme.primary.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                                Icons.wifi_rounded,
                                size: 18,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.6,
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .fadeOut(
                                duration: 1000.ms,
                                begin: 1.0,
                                curve: Curves.easeInOut,
                              )
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.1, 1.1),
                              ),
                        ],
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideX(begin: -0.2, end: 0),
                  _EnvironmentInfo(
                        // Extracted locally
                        theme: theme,
                        temp: liveInfo.temperature,
                        iconName: liveInfo.weatherIcon,
                      )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideX(begin: 0.2, end: 0),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: RoboAssistant(eyesOnly: true))
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 30),
            const TimeDateWidget()
                .animate()
                .fadeIn(delay: 150.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 40),
            StatusCard(voltage: liveInfo.acVoltage, systemState: systemState)
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms)
                .shimmer(
                  duration: 800.ms,
                  color: Colors.white.withOpacity(0.1),
                ),
            const SizedBox(height: 30),
            const _ActionButtons() // Extracted
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

class ControlView extends StatelessWidget {
  const ControlView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(
                'Smart Control',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: const SwitchGrid().animate().fadeIn(duration: 400.ms)),
      ],
    );
  }
}

class _EnvironmentInfo extends StatelessWidget {
  final ThemeData theme;
  final double temp;
  final String iconName;

  const _EnvironmentInfo({
    required this.theme,
    required this.temp,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (iconName.contains('Sun'))
      icon = Icons.wb_sunny_rounded;
    else if (iconName.contains('Cloud'))
      icon = Icons.cloud;
    else if (iconName.contains('Moon'))
      icon = Icons.nights_stay_rounded;
    else
      icon = Icons.wb_sunny_rounded;

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 20),
        const SizedBox(width: 8),
        Text(
          '${temp.toStringAsFixed(1)}°C',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final googleHomeLinked = ref.watch(googleHomeLinkedProvider);
    final assistantService = ref.watch(googleAssistantServiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _GlassButton(
              label: "Google Home",
              icon: Icons.home_rounded,
              isActive: googleHomeLinked.valueOrNull == true,
              theme: theme,
              onTap: () => _showGoogleHomeDialog(context, ref),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _GlassButton(
              label: "Assistant",
              icon: assistantService.isListening
                  ? Icons.mic
                  : Icons.mic_none_rounded,
              isActive: assistantService.isListening,
              theme: theme,
              activeColor: Colors.orangeAccent,
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const GoogleAssistantDialog(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showGoogleHomeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final googleHomeLinked =
              ref.watch(googleHomeLinkedProvider).valueOrNull ?? false;
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
                  Text('Google Home', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
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
                            Navigator.of(context).pop();
                          },
                          child: const Text('Unlink'),
                        ),
                      if (!googleHomeLinked)
                        ElevatedButton(
                          onPressed: () async {
                            await service.linkGoogleHome();
                            Navigator.of(context).pop();
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
}

class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final ThemeData theme;
  final VoidCallback onTap;
  final Color activeColor;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.theme,
    required this.onTap,
    this.activeColor = const Color(0xFF00E676),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: PixelLedBorder(
        colors: isActive
            ? [
                activeColor,
                Colors.white,
                activeColor.withOpacity(0.5),
                Colors.white,
              ]
            : [Colors.white24, Colors.white10, Colors.white24, Colors.white10],
        child: FrostedGlass(
          padding: const EdgeInsets.symmetric(vertical: 16),
          radius: BorderRadius.circular(20),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive
                    ? activeColor
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
