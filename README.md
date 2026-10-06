# Aurexa Smart Light Controller

A clean, responsive mobile app built with Flutter to control your ESP32-based smart lights locally over WiFi. It focuses on simplicity, speed, and providing a great user experience without unnecessary bloat.

## Features

- **Local Network Control:** Communicates directly with your ESP32 over WiFi. No cloud servers required.
- **Auto-Reconnect Logic:** The app and firmware handle network drops and router restarts gracefully, ensuring the connection stays alive.
- **Smart Scheduling:** Set timers and schedules directly within the app. Notifications will alert you when schedules trigger.
- **Dynamic Haptics:** Custom haptic feedback tailored to your phone's vibration motor for a more tactile experience.
- **Multi-Language Support:** Includes localization for English, Hindi, and Malayalam.
- **Clean UI:** Built with an emphasis on smooth animations, easy navigation, and clear status indicators.

## Firmware Setup

The app requires specific firmware running on your ESP32. 

1. Flash your ESP32 with the firmware located in the `firmware/` directory.
2. The ESP32 will host a WebSocket server and broadcast its presence on your local network.
3. The app will automatically discover and connect to the ESP32.

### LED Indicators (ESP32)
- **Blue Strobe:** The ESP32 is active, connected to WiFi, and ready for commands.
- **Red Blink:** The ESP32 is disconnected from the network and trying to reconnect.

## Building the App

This project is built using Flutter. Ensure you have the Flutter SDK installed.

```bash
# Get dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Build a release APK for Android
flutter build apk --release
```

## Supported Devices
- The app supports Android (tested on Samsung and other major brands).
- Haptics are scaled automatically based on whether your phone uses an ERM, Z-axis, or X-axis linear motor.

## License
MIT License. Feel free to use this code for your own personal or commercial smart home projects.
