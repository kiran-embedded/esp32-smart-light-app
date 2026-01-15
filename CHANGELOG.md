# Changelog

All notable changes to Nebula Core will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-27

### 🎉 Initial Release

#### Added
- **Firebase Realtime Database Integration**
  - 100% Firebase-based command/telemetry architecture
  - Dynamic Firebase configuration via UI
  - Real-time bidirectional sync with ESP32 devices
  - Optimistic UI updates with jitter protection
  
- **ESP32 Device Control**
  - Support for 4-channel relay control
  - Universal ESP32 firmware included
  - Automatic device ID generation from chip ID
  - Real-time telemetry monitoring (voltage, current, power)
  
- **User Interface**
  - Stunning glassmorphic design with neon aesthetics
  - Unique HSL-based color gradients per switch
  - Smooth 60fps animations with flutter_animate
  - Dark mode optimized for OLED displays
  - Cinematic splash screen
  
- **Smart Features**
  - AI voice assistant with text-to-speech
  - Speech recognition for hands-free control
  - Context-aware dynamic icon system
  - Dual naming system (local nicknames + Firebase hardware names)
  - Weather integration with location services
  
- **Authentication**
  - Google Sign-In integration
  - Dynamic OAuth configuration
  - Secure Firebase authentication
  
- **Production Ready**
  - Zero hardcoded credentials
  - User-configurable Firebase projects
  - Connection resilience with auto-reconnect
  - Timeout handling and Firebase reset
  - Local storage with SharedPreferences
  
- **Debug Tools**
  - Force hardware sync
  - Firebase path inspector
  - Real-time connection status
  - ADB logcat integration support
  
- **Documentation**
  - Comprehensive README with setup guides
  - Firebase configuration walkthrough
  - ESP32 firmware flashing instructions
  - Architecture documentation
  - Troubleshooting guide

#### Technical Details
- **Framework**: Flutter 3.10.4+
- **State Management**: Riverpod 2.6.1
- **Backend**: Firebase Realtime Database 11.1.0
- **Platforms**: Android (iOS support planned)

---

## [Unreleased]

### Planned Features
- Multi-language support (i18n)
- Scheduling & automation
- Energy analytics dashboard
- Scene management
- iOS support
- Web dashboard
- Push notifications
- Backup/restore functionality

---

## Version History

### Version Numbering
- **Major.Minor.Patch** (e.g., 1.0.0)
- **Major**: Breaking changes
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes

### Release Notes Format
- 🎉 **Added**: New features
- 🔧 **Changed**: Changes in existing functionality
- 🐛 **Fixed**: Bug fixes
- 🗑️ **Removed**: Removed features
- 🔒 **Security**: Security improvements

---

[1.0.0]: https://github.com/kiran-embedded/esp32-smart-light-app/releases/tag/v1.0.0
