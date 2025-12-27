# 🌌 Nebula Core

<div align="center">

**Ultra-Advanced Smart Switch Control System**

[![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![ESP32](https://img.shields.io/badge/ESP32-Compatible-E7352C?logo=espressif&logoColor=white)](https://www.espressif.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*A production-ready Flutter application for controlling ESP32-based smart power grids with real-time Firebase synchronization, MQTT communication, and AI-powered voice control.*

</div>

---

## ✨ Features

### 🎯 Core Functionality
- **🔌 Smart Relay Control** - Control up to 4 relays per ESP32 device with real-time state synchronization
- **🔥 Firebase Integration** - Dynamic Firebase configuration with multi-device support
- **📡 MQTT Communication** - Dual-protocol support (Firebase + MQTT) for robust device control
- **🎨 Premium UI/UX** - Glassmorphic design with neon animations and smooth transitions
- **🤖 AI Voice Assistant** - Text-to-speech and speech recognition for hands-free control
- **⚡ Real-time Telemetry** - Live voltage, current, and power monitoring
- **🌡️ Weather Integration** - Location-based weather data display
- **🔐 Google Sign-In** - Secure authentication with dynamic OAuth configuration

### 🛠️ Advanced Features
- **Multi-Device Management** - Support for unlimited ESP32 devices with unique IDs
- **Custom Switch Naming** - Persistent local and hardware-synced switch names
- **Dynamic Icon System** - Context-aware icons based on switch names
- **Connection Resilience** - Auto-reconnect with timeout handling and Firebase reset
- **Debug Tools** - Built-in diagnostics for Firebase sync and MQTT connections
- **Production Ready** - User-configurable Firebase and MQTT settings

---

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** `>=3.10.4`
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** (free tier supported)
- **ESP32 Development Board** (optional for hardware testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/nebula_core.git
   cd nebula_core
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Build release APK**
   ```bash
   flutter build apk --release
   ```

---

## 🔧 Configuration

### Firebase Setup

Nebula Core supports **dynamic Firebase configuration** - no hardcoded credentials!

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Realtime Database** and **Authentication** (Google Sign-In)
3. Launch the app and navigate to **Settings → Production Setup**
4. Enter your Firebase credentials:
   - API Key
   - Project ID
   - Database URL
   - App ID
   - Messaging Sender ID
   - Web Client ID (for Google Sign-In)

📖 **Detailed Guide**: See [FIREBASE_PRODUCTION_GUIDE.md](FIREBASE_PRODUCTION_GUIDE.md)

### MQTT Setup (Optional)

For direct ESP32 communication via MQTT:

1. Create a free account at [HiveMQ Cloud](https://www.hivemq.com/mqtt-cloud-broker/)
2. Navigate to **Settings → MQTT Configuration** in the app
3. Enter your broker details:
   - Host
   - Port (8883 for TLS, 8884 for WebSocket)
   - Username
   - Password

---

## 🎛️ ESP32 Firmware

### Universal Firmware

The included firmware (`firmware/esp32_nebula_controller.ino`) supports:

- ✅ **Automatic Device ID** generation from ESP32 Chip ID
- ✅ **Firebase command/telemetry** synchronization
- ✅ **Real-time voltage & current** sensing (ACS712 compatible)
- ✅ **4-channel relay control** with state persistence
- ✅ **OTA updates** ready

### Flashing Instructions

1. Open `firmware/esp32_nebula_controller.ino` in Arduino IDE
2. Update Wi-Fi credentials:
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```
3. Install required libraries:
   - `Firebase ESP32 Client`
   - `WiFi`
4. Select your ESP32 board and port
5. Click **Upload**

📖 **Hardware Guide**: See [SETUP_GUIDE.md](SETUP_GUIDE.md)

---

## 📱 App Architecture

### State Management
- **Riverpod** for reactive state management
- **Provider-based architecture** for scalability

### Key Components

```
lib/
├── main.dart                    # App entry point with dynamic Firebase init
├── providers/
│   ├── switch_provider.dart     # Relay state management
│   ├── mqtt_service.dart        # MQTT connection handling
│   └── firebase_config.dart     # Dynamic Firebase configuration
├── screens/
│   ├── home_screen.dart         # Main dashboard
│   ├── settings_screen.dart     # Configuration UI
│   └── firebase_setup_screen.dart
└── widgets/
    ├── switch_grid/             # Animated switch tiles
    ├── robo/                    # AI assistant UI
    └── live_info/               # Telemetry displays
```

---

## 🎨 UI Showcase

### Design Philosophy
- **Glassmorphism** - Frosted glass effects with backdrop blur
- **Neon Aesthetics** - Dynamic color gradients and glow effects
- **Smooth Animations** - 60fps micro-interactions
- **Dark Mode First** - Optimized for OLED displays

### Key Screens
- 🏠 **Home Dashboard** - Live switch grid with telemetry cards
- ⚙️ **Settings** - Firebase, MQTT, and app configuration
- 🤖 **Robo Assistant** - Voice-controlled AI interface
- 📊 **System Status** - Real-time device health monitoring

---

## 🧪 Testing & Debugging

### Debug Features
- **Force Hardware Sync** - Manual Firebase relay name sync
- **Test MQTT Connection** - Validate broker connectivity
- **Firebase Path Inspector** - View raw database snapshots
- **ADB Logcat Integration** - Real-time device logs

### Running Tests
```bash
flutter test
```

---

## 📦 Dependencies

### Core
- `flutter_riverpod` - State management
- `firebase_core` & `firebase_database` - Backend sync
- `mqtt_client` - ESP32 communication
- `google_sign_in` - Authentication

### UI/UX
- `flutter_animate` - Smooth animations
- `glassmorphism` - Modern UI effects
- `shimmer` - Loading states
- `google_fonts` - Typography

### Utilities
- `shared_preferences` - Local storage
- `geolocator` - Location services
- `flutter_tts` & `speech_to_text` - Voice features

📄 **Full list**: See [pubspec.yaml](pubspec.yaml)

---

## 🛣️ Roadmap

- [ ] **Multi-language support** (i18n)
- [ ] **Scheduling & Automation** (timer-based control)
- [ ] **Energy Analytics** (historical power consumption)
- [ ] **Scene Management** (one-tap multi-device control)
- [ ] **iOS Support** (currently Android-focused)
- [ ] **Web Dashboard** (browser-based control panel)

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **Firebase** - For real-time database infrastructure
- **ESP32 Community** - For hardware support and libraries
- **HiveMQ** - For MQTT cloud broker services

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/nebula_core/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/nebula_core/discussions)
- **Email**: your.email@example.com

---

<div align="center">

**Made with ❤️ and Flutter**

⭐ **Star this repo** if you find it useful!

</div>
