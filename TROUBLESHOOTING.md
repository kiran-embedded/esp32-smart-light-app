# 🩺 Troubleshooting Guide

This guide covers common issues you might encounter while setting up or using **Nebula Core** and the **ESP32 Firmware**.

---

## 📱 App Issues

### 🔴 App Stays on "Connecting..."
**Symptoms**: The system status card shows "Connecting..." indefinitely, or the "System Standby" message never changes to "Online".

**Possible Causes & Solutions**:
1.  **Firebase Rules**: Your database might be locked.
    *   *Fix*: Go to Firebase Console -> Realtime Database -> Rules and set `.read` and `.write` to `true` (for testing only).
2.  **Internet Connection**: The emulator or device has no internet.
    *   *Fix*: Ensure you are connected to WiFi/Data.
3.  **Wrong Database URL**: The URL in `app_constants.dart` or your dynamic configuration is incorrect.
    *   *Fix*: It must be exactly `https://your-project.firebaseio.com` (no trailing slash).

### 🔑 Google Sign-In Fails (Error 10/12500)
**Symptoms**: Tapping "Sign in with Google" closes the popup immediately or shows an error snackbar.

**Solution**:
1.  **SHA-1 Fingerprint is Missing**: This is the #1 cause.
2.  **Wrong Package Name**: Your `google-services.json` must match `com.iot.nebulacontroller`.
3.  **Support Email**: You haven't set a support email in Firebase Console -> Project Settings.

👉 **See the dedicated guide**: [TROUBLESHOOTING_GOOGLE_SIGNIN.md](TROUBLESHOOTING_GOOGLE_SIGNIN.md)

### 💾 Settings Not Saving
**Symptoms**: You rename a switch, restart the app, and the name reverts to "Relay 1".

**Solution**:
1.  **SharedPreferences**: The app uses local storage for nicknames.
    *   *Fix*: Clear app data/cache and try again.
2.  **Permission**: Ensure the app has permission to write storage (usually automatic).

---

## 🎛️ ESP32 Hardware Issues

### ⚠️ ESP32 Connects to WiFi but NOT Firebase
**Symptoms**: Serial monitor shows "WiFi Connected" but then "Stream Start Failed" or "Firebase Error".

**Possible Causes & Solutions**:
1.  **Database Secret/API Key**: You are using a Legacy Token (deprecated) or an invalid API Key.
    *   *Fix*: Use the "Web API Key" from Project Settings.
2.  **Time Sync**: Firebase requires correct time.
    *   *Fix*: The provided firmware handles NTP automatically, but ensure your network allows NTP traffic (UDP port 123).
3.  **Database URL**: The firmware needs the *host* without `https://`.
    *   *Correct*: `your-project.firebaseio.com`
    *   *Incorrect*: `https://your-project.firebaseio.com/`

### 💡 Relays Click but No Status Update in App
**Symptoms**: Physical relays work, but the app toggle bounces back to the previous state.

**Solution**:
1.  **Telemetry Path**: The ESP32 is writing to the wrong path.
    *   *Fix*: Ensure the device ID in the firmware matches the device ID in the app.
    *   *Default ID*: `79215788` (derived from MAC address in the sample code).
2.  **Listener**: The app's stream listener isn't active.
    *   *Fix*: Restart the app.

---

## 🆘 Critical Errors

### "Red Screen of Death" (Flutter Error)
If you see a red screen during development:
1.  **Run `flutter clean`**: Clears stale build artifacts.
2.  **Run `flutter pub get`**: Refreshes dependencies.
3.  **Check Logs**: Run `flutter run` in the terminal to see the exact error stack trace.

### ESP32 Crash / Reboot Loop
**Symptoms**: The ESP32 constantly restarts (brownout).

**Solution**:
1.  **Power Supply!**: This is almost always a weak power supply.
    *   *Fix*: Use a quality 5V/2A adapter. Do NOT power relays solely from USB.
2.  **Capacitor**: Add a 100uF capacitor across the 5V/GND rails.

---

## 📞 Still Stuck?

If these steps don't help, verify your setup against the [SETUP_GUIDE.md](SETUP_GUIDE.md) or open an issue on GitHub.
