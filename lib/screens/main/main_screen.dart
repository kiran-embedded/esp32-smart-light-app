import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../../services/google_assistant_service.dart';
import '../../services/user_activity_service.dart';

import 'dart:async';
import '../../services/firebase_switch_service.dart';
import '../../providers/switch_provider.dart';

import '../../providers/switch_schedule_provider.dart';
import '../../providers/animation_provider.dart';
import '../../providers/google_home_provider.dart';
import '../../providers/live_info_provider.dart';

import '../../widgets/robo/robo_assistant.dart';
import '../../widgets/robo/robo_assistant.dart' as robo;
import '../../widgets/live_info/time_date_widget.dart';
import '../../widgets/live_info/status_card.dart';
import '../../widgets/switch_grid/switch_grid.dart';
import '../../widgets/voice/voice_assistant_overlay.dart';
import '../../widgets/common/frosted_glass.dart';
import '../../widgets/common/pixel_led_border.dart';
import '../../widgets/common/switch_tab_background.dart';
import '../../widgets/common/no_internet_widget.dart';
import '../../widgets/navigation/animated_nav_icon.dart';
import '../../widgets/scheduling/scheduling_sheet.dart';
import '../../widgets/common/premium_app_bar.dart';

import '../settings/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _ignoreOffline = false;

  Timer? _schedulerTimer;
  final Map<String, DateTime> _lastFiredSchedules = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(userActivityServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      robo.triggerRoboReaction(ref, robo.RoboReaction.wakeUp);
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(soundServiceProvider).playStartup();
      });
    });

    // Foreground Scheduler (Fallback "AI" Logic)
    _schedulerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkSchedules();
    });
  }

  void _checkSchedules() {
    final now = DateTime.now();
    final schedules = ref.read(switchScheduleProvider);
    final switchService = ref.read(firebaseSwitchServiceProvider);

    for (final schedule in schedules) {
      if (!schedule.isEnabled) continue;

      // Check Time Match (Hour & Minute)
      if (schedule.hour == now.hour && schedule.minute == now.minute) {
        // Check Day Match (if specific days selected)
        if (schedule.days.isNotEmpty && !schedule.days.contains(now.weekday)) {
          continue;
        }

        // Check if already fired strictly within this minute
        final lastFired = _lastFiredSchedules[schedule.id];
        if (lastFired != null &&
            lastFired.year == now.year &&
            lastFired.month == now.month &&
            lastFired.day == now.day &&
            lastFired.hour == now.hour &&
            lastFired.minute == now.minute) {
          continue; // Already fired this minute
        }

        // FIRE COMMAND: 0=ON, 1=OFF (Active Low)
        final commandValue = schedule.targetState ? 0 : 1;
        switchService.sendCommand(schedule.relayId, commandValue);

        // Mark as fired
        _lastFiredSchedules[schedule.id] = now;

        print(
          'Foreground Scheduler: Executed ${schedule.relayId} -> ${schedule.targetState}',
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _schedulerTimer?.cancel();
    super.dispose();
  }

  // ... (rest of class)

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _ignoreOffline = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _ignoreOffline = false;
          });
        }
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onBottomNavTapped(int index) {
    if (_currentPage == index) return;

    HapticService.selection();
    ref.read(soundServiceProvider).playTabSwitch();

    // Trigger Look/Blink
    robo.triggerRoboReaction(ref, robo.RoboReaction.blink);

    setState(() => _currentPage = index);

    // Apply User's Fluidity Setting
    final animSettings = ref.read(animationSettingsProvider);

    if (animSettings.uiType == UiTransitionAnimation.zeroLatency) {
      // Instant snap
      _pageController.jumpToPage(index);
    } else {
      // Dynamic curves based on selection
      Curve curve = Curves.easeOut;
      Duration duration = const Duration(milliseconds: 300);

      switch (animSettings.uiType) {
        case UiTransitionAnimation.iOSSlide:
        case UiTransitionAnimation.iosExactSlide:
          curve = Curves.fastLinearToSlowEaseIn; // classic iOS push feel
          duration = const Duration(milliseconds: 400);
          break;
        case UiTransitionAnimation.butterZoom:
          curve = Curves.easeInOutCubic;
          duration = const Duration(milliseconds: 350);
          break;
        case UiTransitionAnimation.elasticSnap:
          curve = Curves.elasticOut;
          duration = const Duration(milliseconds: 600);
          break;
        case UiTransitionAnimation.fluidFade:
          curve = Curves.easeOutQuad;
          break;
        default:
          curve = Curves.fastOutSlowIn;
      }

      _pageController.animateToPage(index, duration: duration, curve: curve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('.info/connected').onValue,
      builder: (context, snapshot) {
        final isConnected = (snapshot.data?.snapshot.value as bool?) ?? true;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          bottomNavigationBar: _buildBottomNav(theme),
          body: Stack(
            children: [
              // Base Layer (Solid Black Void)
              Positioned.fill(child: ColoredBox(color: Colors.black)),

              // Background Layer - Restored below header
              Positioned.fill(
                top:
                    85 +
                    MediaQuery.of(
                      context,
                    ).padding.top, // Start strictly at grid level
                child: ClipRect(
                  // Force clip to prevent particle bleeding
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    opacity: _currentPage == 1 ? 1.0 : 0.0,
                    child: const SwitchTabBackground(child: SizedBox.expand()),
                  ),
                ),
              ),

              // Content Layer
              SafeArea(
                bottom: false,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    DashboardView(),
                    ControlView(),
                    SettingsScreen(),
                  ],
                ),
              ),

              // No Internet Overlay
              if (!isConnected && !_ignoreOffline)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: NoInternetWidget(
                        onRetry: () => HapticService.selection(),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          child: BottomNavigationBar(
            currentIndex: _currentPage,
            onTap: _onBottomNavTapped,
            backgroundColor: Colors.transparent,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.white.withOpacity(0.3),
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: [
              _buildNavItem(Icons.dashboard_rounded, 'CORE', 0),
              _buildNavItem(Icons.grid_view_rounded, 'GRID', 1),
              _buildNavItem(Icons.settings_suggest_rounded, 'SETUP', 2),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: AnimatedNavIcon(icon: icon, isSelected: false, label: label),
      activeIcon: AnimatedNavIcon(icon: icon, isSelected: true, label: label),
      label: label,
    );
  }
}

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final liveInfo = ref.watch(liveInfoProvider);
    final systemState = liveInfo.acVoltage > 0
        ? "GRID SYNC ACTIVE\nNebula Protection Enabled"
        : "GRID OFFLINE\nMonitoring Power State";

    return Stack(
      children: [
        // Content with dynamic spacing
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 65), // Account for App Bar
                const Spacer(flex: 1), // Top breathing room
                const RoboAssistant(eyesOnly: true, autoTuneEnabled: false),
                const Spacer(flex: 1),
                const TimeDateWidget(),
                const Spacer(flex: 1),
                StatusCard(
                  voltage: liveInfo.acVoltage,
                  systemState: systemState,
                ),
                const Spacer(flex: 2), // LARGER gap to push buttons lower
                const _ActionButtons(),
                const Spacer(flex: 1), // Bottom breathing room
              ],
            ),
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PremiumAppBar(
            title: Text(
              'NEBULA CORE',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
                shadows: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            trailing: _EnvironmentInfo(
              theme: theme,
              temp: liveInfo.temperature,
              iconName: liveInfo.weatherIcon,
            ),
          ),
        ),
      ],
    );
  }
}

class ControlView extends ConsumerStatefulWidget {
  const ControlView({super.key});

  @override
  ConsumerState<ControlView> createState() => _ControlViewState();
}

class _ControlViewState extends ConsumerState<ControlView> {
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    // No artificial delay for instant switch accessibility
    _isInitComplete = true;
  }

  @override
  Widget build(BuildContext context) {
    // Consistent spacing strategy
    final topPadding = MediaQuery.of(context).padding.top;
    final contentTopPadding = topPadding + 65 + 20;

    return Stack(
      children: [
        if (!_isInitComplete)
          Center(
            child: Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.only(
              top: contentTopPadding, // Aligned with Dashboard
            ),
            child: ClipRect(child: SwitchGrid()),
          ),

        // PREMIUM APP BAR
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PremiumAppBar(
            title: Text(
              'SMART SWITCHES',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: const Color(0xFF00E5FF), // Neon Cyan
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Fixed spacing for Environment Info to look premium
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
    IconData icon = iconName.contains('Sun')
        ? Icons.wb_sunny_rounded
        : iconName.contains('Cloud')
        ? Icons.cloud
        : iconName.contains('Moon')
        ? Icons.nights_stay_rounded
        : Icons.wb_sunny_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.secondary,
            size: 16,
          ), // Smaller icon
          const SizedBox(width: 8),
          Text(
            '${temp.toStringAsFixed(1)}°C',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
        ],
      ),
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
                await showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.transparent, // Removed blur barrier
                  isScrollControlled: true,
                  builder: (context) => const VoiceAssistantOverlay(),
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
        enableInfiniteRainbow: true,
        duration: const Duration(seconds: 4),
        colors: const [],
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
