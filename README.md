# Aurexa Smart Light Controller

A clean, responsive mobile app built with Flutter to control your ESP32-based smart lights. It focuses on simplicity, speed, and providing a great user experience.

## Features & Improvements in v1.0.0

- **Cloud-Based Architecture:** Aurexa is a fully cloud-based app using Firebase Authentication and Realtime Database. Users log in with a common Firebase backend to securely control their devices from anywhere in the world—not just on local WiFi.
- **Improved ESP32 Flasher:** The built-in firmware flasher tool has been significantly improved for faster and more reliable flashing directly from your phone.
- **Dynamic Haptics:** Custom haptic feedback tailored to your phone's vibration motor for a more tactile experience.
- **Language Translations (Beta):** We've introduced Hindi and Malayalam language support. (Currently in Beta, bugs are being ironed out).
- **Auto-Reconnect Logic:** The app and firmware handle network drops and router restarts gracefully.

## Upcoming Features (Future Releases)

- **GPS-Based Automation:** Automatically turn on your streetlights or home lights the moment you arrive home using GPS geofencing.
- **Further Optimizations:** More performance and battery optimizations are planned for upcoming releases to make the app even smoother.

## Firmware Setup

The app requires specific firmware running on your ESP32. 

1. Flash your ESP32 with the firmware located in the `firmware/` directory (or use the built-in flasher).
2. The ESP32 will connect to Firebase.
3. The app will communicate securely through the cloud.

### LED Indicators (ESP32)
- **Blue Strobe:** The ESP32 is active, connected to WiFi, and ready for commands.
- **Red Blink:** The ESP32 is disconnected from the network and trying to reconnect.

## Building the App

This project is built using Flutter. Ensure you have the Flutter SDK installed.

```bash
flutter pub get
flutter build apk --release
```

## License
MIT License. Feel free to use this code for your own smart home projects.
