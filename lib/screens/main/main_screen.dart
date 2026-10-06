import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/switch_provider.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../services/user_activity_service.dart';
import '../../services/sound_service.dart';
import '../../services/haptic_service.dart';

import '../../widgets/navigation/custom_bottom_nav.dart';
import '../../widgets/bot/bot_assistant.dart' as bot;
import '../settings/settings_screen.dart';
import 'home/home_view.dart';
import 'switches/switches_view.dart';
import 'timers/timers_view.dart';
import '../../widgets/help/help_bot_overlay.dart';

final helpBotVisibleProvider = StateProvider<bool>((ref) => false);
final mainScreenStateProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  Timer? _schedulerTimer;
  final Map<String, DateTime> _lastFiredSchedules = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(userActivityServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bot.triggerBotReaction(ref, bot.BotReaction.wakeUp);
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(soundServiceProvider).playStartup();
      });
    });

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

      if (schedule.hour == now.hour && schedule.minute == now.minute) {
        if (schedule.days.isNotEmpty && !schedule.days.contains(now.weekday)) {
          continue;
        }

        final lastFired = _lastFiredSchedules[schedule.id];
        if (lastFired != null &&
            lastFired.year == now.year &&
            lastFired.month == now.month &&
            lastFired.day == now.day &&
            lastFired.hour == now.hour &&
            lastFired.minute == now.minute) {
          continue;
        }

        final commandValue = schedule.targetState ? 1 : 0;
        switchService.sendCommand(
          schedule.relayId,
          commandValue,
          triggeredBy: 'scheduler',
        );

        _lastFiredSchedules[schedule.id] = now;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _schedulerTimer?.cancel();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    final currentPage = ref.watch(mainScreenStateProvider);
    if (currentPage == index) return;

    HapticService.selection();
    final soundService = ref.read(soundServiceProvider);
    Future.microtask(() => soundService.playTabSwitch());

    bot.triggerBotReaction(ref, bot.BotReaction.blink);

    ref.read(mainScreenStateProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPage = ref.watch(mainScreenStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: false,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentPage,
        onTap: _onBottomNavTapped,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: theme.scaffoldBackgroundColor)),

          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: currentPage,
              children: [
                _buildFadeTab(0, currentPage, const HomeView()),
                _buildFadeTab(1, currentPage, const SwitchesView()),
                _buildFadeTab(2, currentPage, const TimersView()),
                _buildFadeTab(3, currentPage, const SettingsScreen()),
              ],
            ),
          ),
          if (ref.watch(helpBotVisibleProvider))
            HelpBotOverlay(
              onComplete: () =>
                  ref.read(helpBotVisibleProvider.notifier).state = false,
            ),
        ],
      ),
    );
  }

  Widget _buildFadeTab(int index, int currentPage, Widget child) {
    return AnimatedOpacity(
      opacity: currentPage == index ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: currentPage == index ? 1.0 : 0.96,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: currentPage != index,
          child: child,
        ),
      ),
    );
  }
}

