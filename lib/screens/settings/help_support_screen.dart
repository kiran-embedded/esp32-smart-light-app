import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/esp32_code_generator.dart';
import '../../core/constants/app_constants.dart';
import '../../services/file_service.dart';
import '../../providers/switch_provider.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Welcome to Aurexa Home",
      "content": "Aurexa Home is a highly optimized, zero-latency Smart Light control application.\n\nThis application uses advanced logic to synchronize with ESP32 and ESP8266 controllers natively without delay.\n\nSwipe left to continue learning how to setup and use your devices.",
    },
    {
      "title": "How do I control my devices?",
      "content": "To control your devices, navigate to the Home tab or Switches tab.\n\nSimply tap any switch card to toggle the relay. The app uses an optimistic UI approach, meaning the visual toggle happens instantly, while the command is sent to the Cloud in the background.\n\nThis ensures a buttery smooth experience with zero wait time.",
    },
    {
      "title": "Firebase Setup (Step 1)",
      "content": "1. Go to console.firebase.google.com and create a new project.\n\n2. Add an Android app to your project with the package name: com.aurexa.app\n\n3. Download the google-services.json file, but since we are using RTDB directly via REST/Stream on ESP32, you mainly need the Database URL and API Key.",
    },
    {
      "title": "Firebase Setup (Step 2)",
      "content": "4. Go to Build > Realtime Database and click 'Create Database'.\n\n5. Start in Test Mode, or configure your rules to allow read/write access (e.g., { \".read\": true, \".write\": true }).\n\n6. Copy your Database URL (e.g., https://your-project.firebaseio.com) and your Web API Key from Project Settings.",
    },
    {
      "title": "ESP32 Firmware Flashing",
      "content": "You can generate the ESP32 C++ firmware directly from this app!\n\n1. Ensure you have the Arduino IDE installed.\n2. Tap the 'Generate Firmware' button on the final page of this guide.\n3. Paste the generated code into Arduino IDE.\n4. Install the 'Firebase ESP Client' library by Mobizt.\n5. Flash to your ESP32.",
    },
    {
      "title": "Advanced Auto Recovery",
      "content": "Your ESP32 is equipped with advanced WiFi auto-recovery.\n\nIf your WiFi router loses power or restarts, the ESP32 will continuously scan and seamlessly reconnect once the network is available.\n\nYou do NOT need to restart the ESP32. The LED will blink blue when the connection is fully restored and active.",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showEsp32FirmwareDialog(BuildContext context, WidgetRef ref) {
    final devices = ref.read(switchDevicesProvider);
    final code = Esp32CodeGenerator.generateFirebaseFirmware(
      devices: devices,
      wifiSsid: AppConstants.defaultWifiSsid,
      wifiPassword: AppConstants.defaultWifiPassword,
      firebaseApiKey: 'YOUR_FIREBASE_API_KEY',
      firebaseDatabaseUrl: 'YOUR_FIREBASE_DATABASE_URL',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'ESP32 Firmware',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Copy this code to your Arduino IDE.",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF00FFC2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FFC2),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final fileService = FileService();
              await fileService.copyToClipboard(code);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                    backgroundColor: Color(0xFF00FFC2),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Copy Code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Help & Support",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page["title"]!,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        page["content"]!,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          height: 1.6,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      if (index == _pages.length - 1) ...[
                        const SizedBox(height: 40),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBB86FC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            onPressed: () => _showEsp32FirmwareDialog(context, ref),
                            icon: const Icon(Icons.memory),
                            label: const Text("Generate ESP32 Firmware"),
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFF00FFC2) : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
