import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/switch_device.dart';
import '../../providers/neural_logic_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/live_info_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/system/display_engine.dart';

class NeuralMappingView extends ConsumerStatefulWidget {
  const NeuralMappingView({super.key});

  @override
  ConsumerState<NeuralMappingView> createState() => _NeuralMappingViewState();
}

class _NeuralMappingViewState extends ConsumerState<NeuralMappingView>
    with TickerProviderStateMixin {
  String? _selectedPirKey;

  static const List<Color> _sensorColors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
  ];

  static const List<Color> _relayColors = [
    Color(0xFF64FFDA),
    Color(0xFFFF6E40),
    Color(0xFF448AFF),
    Color(0xFFFFD740),
    Color(0xFFB388FF),
    Color(0xFF69F0AE),
    Color(0xFFFF80AB),
  ];

  // ─── HANDLERS ─────────────────────────────────────────────
  void _handleTapPir(String key) {
    HapticService.selection();
    setState(() => _selectedPirKey = (_selectedPirKey == key) ? null : key);
  }

  void _handleTapRelay(int index) {
    if (_selectedPirKey != null) {
      HapticService.medium();
      // Extract numeric index from PIR key (e.g., "PIR1" -> 1 -> 0 index) or use the key directly if supported
      final int pirIdx =
          int.tryParse(_selectedPirKey!.replaceAll('PIR', '')) ?? 1;
      ref.read(neuralLogicProvider.notifier).toggleLink(pirIdx - 1, index);
    } else {
      HapticService.selection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Select a sensor first",
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: Colors.white.withOpacity(0.05),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
          width: 200,
        ),
      );
    }
  }

  void _handleClearAll(int pirIndex) {
    HapticService.heavy();
    ref.read(neuralLogicProvider.notifier).clearMapping(pirIndex);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Links cleared for Sensor ${pirIndex + 1}"),
        backgroundColor: Colors.white10,
        behavior: SnackBarBehavior.floating,
        width: 200,
      ),
    );
  }

  void _handleDeleteSensor(String pirKey) {
    HapticService.heavy();
    final securityState = ref.read(securityProvider);
    final pirName = securityState.sensors[pirKey]?.nickname ?? pirKey;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        title: Text(
          "Delete Sensor?",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Permanently remove $pirName from the system?",
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticService.impactWarning();
              ref.read(securityProvider.notifier).deleteSensor(pirKey);
              Navigator.pop(context);
              setState(() => _selectedPirKey = null);
            },
            child: Text(
              "DELETE",
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    String title,
    String initialValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter name",
            hintStyle: GoogleFonts.outfit(color: Colors.white24),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(
              "SAVE",
              style: GoogleFonts.outfit(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showSensorMenu(String pirKey) {
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(DisplayEngine.p(24)),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: DisplayEngine.h(24)),
            ListTile(
              leading: const Icon(
                Icons.link_off_rounded,
                color: Colors.cyanAccent,
              ),
              title: Text(
                "Clear All Links",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                final int pirIdx =
                    int.tryParse(pirKey.replaceAll('PIR', '')) ?? 1;
                _handleClearAll(pirIdx - 1);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_rounded,
                color: Colors.amberAccent,
              ),
              title: Text(
                "Rename Sensor",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                final secState = ref.read(securityProvider);
                final pirName = secState.sensors[pirKey]?.nickname ?? pirKey;
                _showRenameDialog(
                  "RENAME SENSOR",
                  pirName,
                  (newName) => ref
                      .read(securityProvider.notifier)
                      .renameSensor(pirKey, newName),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              title: Text(
                "Delete Sensor",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleDeleteSensor(pirKey);
              },
            ),
            SizedBox(height: DisplayEngine.h(16)),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(neuralLogicProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            _buildTimerSlider(theme, state),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableH = constraints.maxHeight;
                  final availableW = constraints.maxWidth;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DisplayEngine.p(16),
                      vertical: DisplayEngine.p(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── SENSOR COLUMN ──
                        SizedBox(
                          width: (availableW - DisplayEngine.p(40)) * 0.44,
                          child: _buildSensorColumn(state, availableH),
                        ),
                        // ── CONNECTOR AREA ──
                        Expanded(child: _buildConnectorArea(state)),
                        // ── RELAY COLUMN ──
                        SizedBox(
                          width: (availableW - DisplayEngine.p(40)) * 0.44,
                          child: _buildRelayColumn(state, availableH),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(
        top: DisplayEngine.h(8),
        bottom: DisplayEngine.h(4),
        left: DisplayEngine.p(16),
        right: DisplayEngine.p(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: DisplayEngine.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NEURAL GRID",
                  style: GoogleFonts.outfit(
                    fontSize: DisplayEngine.sp(16),
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 3,
                  ),
                ).animate().shimmer(duration: 3.seconds, color: Colors.white24),
                Row(
                  children: [
                    Text(
                      "V2.5 INDUSTRIAL PRO",
                      style: GoogleFonts.outfit(
                        fontSize: DisplayEngine.sp(7),
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(width: DisplayEngine.w(8)),
                    Consumer(
                      builder: (context, ref, child) {
                        final liveInfo = ref.watch(liveInfoProvider);
                        return Text(
                          "PKT: ${liveInfo.teleId}",
                          style: GoogleFonts.outfit(
                            fontSize: DisplayEngine.sp(7),
                            fontWeight: FontWeight.w900,
                            color: Colors.white24,
                            letterSpacing: 1,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── BUZZER TOGGLE ──
          Consumer(
            builder: (context, ref, child) {
              final isMuted = ref.watch(securityProvider).isBuzzerMuted;
              return GestureDetector(
                onTap: () {
                  HapticService.medium();
                  ref.read(securityProvider.notifier).toggleBuzzerMute();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(DisplayEngine.p(8)),
                  decoration: BoxDecoration(
                    color: isMuted
                        ? Colors.redAccent.withOpacity(0.15)
                        : Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMuted
                          ? Colors.redAccent.withOpacity(0.3)
                          : Colors.greenAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: isMuted ? Colors.redAccent : Colors.greenAccent,
                    size: DisplayEngine.sp(16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.15);
  }

  // ─── TIMER SLIDER ─────────────────────────────────────────
  Widget _buildTimerSlider(ThemeData theme, NeuralLogicState state) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DisplayEngine.p(20),
        vertical: DisplayEngine.p(6),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: DisplayEngine.p(16),
        vertical: DisplayEngine.p(10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(DisplayEngine.r(20)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: Colors.white24,
            size: DisplayEngine.sp(16),
          ),
          SizedBox(width: DisplayEngine.w(8)),
          Text(
            "AUTO-OFF",
            style: GoogleFonts.outfit(
              fontSize: DisplayEngine.sp(8),
              color: Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: DisplayEngine.w(8)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: Colors.white.withOpacity(0.05),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: state.pirTimer.toDouble(),
                min: 5,
                max: 300,
                divisions: 59,
                onChanged: (v) {
                  HapticService.immersiveSliderFeedback(
                    v.toDouble(),
                    min: 5,
                    max: 300,
                  );
                  ref.read(neuralLogicProvider.notifier).updateTimer(v.toInt());
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DisplayEngine.p(8),
              vertical: DisplayEngine.p(3),
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DisplayEngine.r(6)),
            ),
            child: Text(
              "${state.pirTimer}s",
              style: GoogleFonts.outfit(
                fontSize: DisplayEngine.sp(12),
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05);
  }

  // ─── SENSOR COLUMN ────────────────────────────────────────
  Widget _buildSensorColumn(NeuralLogicState state, double availH) {
    final securityState = ref.watch(securityProvider);
    final sensorKeys = securityState.sensors.keys.toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: DisplayEngine.h(6)),
          child: Text(
            "SENSORS",
            style: GoogleFonts.outfit(
              fontSize: DisplayEngine.sp(8),
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: sensorKeys.length,
            padding: EdgeInsets.only(top: DisplayEngine.h(10)),
            separatorBuilder: (_, __) => SizedBox(height: DisplayEngine.h(10)),
            itemBuilder: (_, i) => _buildSensorPill(sensorKeys[i], i, state),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorPill(String pirKey, int index, NeuralLogicState state) {
    final isSelected = _selectedPirKey == pirKey;
    final color = _sensorColors[index % _sensorColors.length];

    // Convert key to hardware index (0-4) for mapping logic
    final int hardwareIdx =
        (int.tryParse(pirKey.replaceAll('PIR', '')) ?? 1) - 1;
    final hasLinks = state.pirMap[hardwareIdx]?.isNotEmpty ?? false;

    final securityState = ref.watch(securityProvider);
    final pirName = securityState.sensors[pirKey]?.nickname ?? pirKey;

    final pillH = DisplayEngine.h(62);

    Widget pill = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: pillH,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.18)
            : (hasLinks
                  ? color.withOpacity(0.08)
                  : Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(DisplayEngine.r(16)),
        border: Border.all(
          color: isSelected
              ? color
              : (hasLinks
                    ? color.withOpacity(0.3)
                    : Colors.white.withOpacity(0.08)),
          width: isSelected ? 1.5 : 0.8,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(width: DisplayEngine.w(8)),
          // ── Color Accent Dot ──
          Container(
            width: pillH - DisplayEngine.p(24),
            height: pillH - DisplayEngine.p(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? color
                  : (hasLinks
                        ? color.withOpacity(0.25)
                        : Colors.white.withOpacity(0.08)),
            ),
            child: Icon(
              Icons.sensors_rounded,
              color: isSelected
                  ? Colors.black
                  : (hasLinks ? color : Colors.white30),
              size: DisplayEngine.sp(20),
            ),
          ),
          SizedBox(width: DisplayEngine.w(12)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pirName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: DisplayEngine.sp(11),
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasLinks)
                  Text(
                    "${state.pirMap[index]?.length} LINKS",
                    style: GoogleFonts.outfit(
                      fontSize: DisplayEngine.sp(7),
                      color: color.withOpacity(0.6),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            Padding(
              padding: EdgeInsets.only(right: DisplayEngine.p(12)),
              child: Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: DisplayEngine.sp(16),
              ),
            ),
        ],
      ),
    );

    if (isSelected) {
      pill = pill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1000.ms,
            curve: Curves.elasticOut,
          );
    }

    return GestureDetector(
      onTap: () => _handleTapPir(pirKey),
      onLongPress: () => _showSensorMenu(pirKey),
      child: pill,
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: -0.15);
  }

  // ─── CONNECTOR AREA (VISUAL LINKS) ───────────────────────
  Widget _buildConnectorArea(NeuralLogicState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedPirKey != null) ...[
            Builder(
              builder: (context) {
                final int pirIdx =
                    (int.tryParse(_selectedPirKey!.replaceAll('PIR', '')) ??
                        1) -
                    1;
                return Icon(
                  Icons.link_rounded,
                  color: _sensorColors[pirIdx % _sensorColors.length]
                      .withOpacity(0.6),
                  size: DisplayEngine.sp(20),
                );
              },
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            SizedBox(height: DisplayEngine.h(8)),
            Builder(
              builder: (context) {
                final int pirIdx =
                    (int.tryParse(_selectedPirKey!.replaceAll('PIR', '')) ??
                        1) -
                    1;
                return Text(
                  "MAPPING",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: DisplayEngine.sp(6),
                    fontWeight: FontWeight.w900,
                    color: _sensorColors[pirIdx % _sensorColors.length]
                        .withOpacity(0.6),
                    letterSpacing: 1.5,
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              width: 1,
              height: DisplayEngine.h(100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
            SizedBox(height: DisplayEngine.h(12)),
            RotatedBox(
              quarterTurns: 1,
              child: Text(
                "SELECT SENSOR",
                style: GoogleFonts.outfit(
                  fontSize: DisplayEngine.sp(7),
                  fontWeight: FontWeight.w900,
                  color: Colors.white10,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── RELAY COLUMN ─────────────────────────────────────────
  Widget _buildRelayColumn(NeuralLogicState state, double availH) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: DisplayEngine.h(6)),
          child: Text(
            "RELAYS",
            style: GoogleFonts.outfit(
              fontSize: DisplayEngine.sp(8),
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: 7,
            padding: EdgeInsets.only(top: DisplayEngine.h(10)),
            separatorBuilder: (_, __) => SizedBox(height: DisplayEngine.h(10)),
            itemBuilder: (_, i) => _buildRelayPill(i, state),
          ),
        ),
      ],
    );
  }

  Widget _buildRelayPill(int index, NeuralLogicState state) {
    final List<int> linkedPirs = [];
    state.pirMap.forEach((pirIdx, relays) {
      if (relays.contains(index)) linkedPirs.add(pirIdx);
    });

    final isLinkedToSelected =
        _selectedPirKey != null &&
        linkedPirs.contains(
          (int.tryParse(_selectedPirKey!.replaceAll('PIR', '')) ?? 1) - 1,
        );
    final hasLinks = linkedPirs.isNotEmpty;

    final switchDevices = ref.watch(switchDevicesProvider);
    final relayId = "relay${index + 1}";
    final relay = switchDevices.firstWhere(
      (d) => d.id == relayId,
      orElse: () => SwitchDevice(
        id: relayId,
        name: "Relay ${index + 1}",
        icon: 'bolt',
        gpioPin: 0,
        mqttTopic: '',
      ),
    );

    final accentColor = _selectedPirKey != null
        ? _sensorColors[((int.tryParse(
                        _selectedPirKey!.replaceAll('PIR', ''),
                      ) ??
                      1) -
                  1) %
              _sensorColors.length]
        : _relayColors[index];

    final pillH = DisplayEngine.h(62);

    return GestureDetector(
      onTap: () => _handleTapRelay(index),
      onDoubleTap: () {
        HapticService.medium();
        _showRenameDialog(
          "RENAME RELAY",
          relay.nickname ?? relay.name,
          (newName) => ref
              .read(switchDevicesProvider.notifier)
              .updateNickname(relayId, newName),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: pillH,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isLinkedToSelected
              ? accentColor.withOpacity(0.18)
              : (hasLinks
                    ? accentColor.withOpacity(0.08)
                    : Colors.white.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(DisplayEngine.r(16)),
          border: Border.all(
            color: isLinkedToSelected
                ? accentColor
                : (hasLinks
                      ? accentColor.withOpacity(0.3)
                      : Colors.white.withOpacity(0.08)),
            width: isLinkedToSelected ? 1.5 : 0.8,
          ),
          boxShadow: isLinkedToSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            SizedBox(width: DisplayEngine.w(8)),
            // ── Accent Dot ──
            Container(
              width: pillH - DisplayEngine.p(24),
              height: pillH - DisplayEngine.p(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLinkedToSelected
                    ? accentColor
                    : (hasLinks
                          ? accentColor.withOpacity(0.25)
                          : Colors.white.withOpacity(0.08)),
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                color: isLinkedToSelected
                    ? Colors.black
                    : (hasLinks ? accentColor : Colors.white24),
                size: DisplayEngine.sp(18),
              ),
            ),
            SizedBox(width: DisplayEngine.w(12)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (relay.nickname ?? relay.name).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: DisplayEngine.sp(10),
                      color: isLinkedToSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontWeight: isLinkedToSelected
                          ? FontWeight.w900
                          : FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (hasLinks)
                    Text(
                      "LINKED",
                      style: GoogleFonts.outfit(
                        fontSize: DisplayEngine.sp(6),
                        color: accentColor.withOpacity(0.6),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.1);
  }

  // ─── FOOTER ───────────────────────────────────────────────
  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: DisplayEngine.p(12),
        horizontal: DisplayEngine.p(24),
      ),
      child:
          Text(
                _selectedPirKey == null
                    ? "SELECT SENSOR TO BEGIN MAPPING"
                    : "LINKING SENSOR ${_selectedPirKey!} • TAP RELAYS",
                style: GoogleFonts.outfit(
                  fontSize: DisplayEngine.sp(9),
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2.seconds, color: Colors.white24),
    );
  }
}
