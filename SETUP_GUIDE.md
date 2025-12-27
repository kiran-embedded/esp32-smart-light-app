# NEBULA CORE - Setup & Configuration Guide

## 🚀 Quick Start

### What Works IMMEDIATELY (No Setup Required):
✅ **Local Mode** - All switch controls work locally via MQTT  
✅ **ESP32 Code Generation** - Generate firmware code  
✅ **Scheduling** - Local schedule execution  
✅ **Voice Feedback** - AI voice responses (TTS)  
✅ **Themes** - All 3 themes work  
✅ **UI/UX** - All animations and interactions  

### What Requires Setup:
⚠️ **Firebase** - For Google Sign-In & Cloud sync  
⚠️ **Google Home** - Requires Firebase setup  
⚠️ **Google Assistant** - Requires microphone permissions  
⚠️ **Relay Module** (4-Channel, 5V)
⚠️ **Power Supply** (Hi-Link 5V or Buck Converter)
⚠️ **Weather API** - Optional (currently uses mock data)  

---

> **💡 Wiring Diagram**: Check out the [Interactive High-Def Schematic](../docs/NEBULA_SCHEMATIC.html) for a detailed view of all connections.

## ⚡ Wiring Instructions

## 📋 Setup Instructions

### 1. Firebase Setup (Required for Google Sign-In & Google Home)

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "Nebula Core"
4. Follow setup wizard

#### Step 2: Add Android App
1. In Firebase Console → Project Settings → Add App → Android
2. Package name: `com.example.nebula_core` (check your `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### Step 3: Add iOS App (if needed)
1. In Firebase Console → Add App → iOS
2. Bundle ID: Check `ios/Runner/Info.plist`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

#### Step 4: Enable Authentication
1. Firebase Console → Authentication → Sign-in method
2. Enable "Google" sign-in provider
3. Add your app's SHA-1 fingerprint (for Android)

#### Step 5: Enable Firestore
1. Firebase Console → Firestore Database
2. Click "Create Database"
3. Start in "Test mode" (for development)
4. Choose location

#### Step 6: Update Android Build Files
Add to `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // Add this
}

dependencies {
    // ... existing dependencies
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
```

Add to `android/build.gradle.kts`:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0") // Add this
    }
}
```

#### Step 7: Update iOS (if needed)
Add to `ios/Podfile`:
```ruby
platform :ios, '12.0'
use_frameworks!

target 'Runner' do
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
end
```

Then run: `cd ios && pod install`

---

### 2. Google Home Integration

#### How It Works:
1. **Link Google Home**: User taps Google Home pill → Links account
2. **Device Sync**: All devices sync to Firestore automatically
3. **Bidirectional**: Changes from Google Home app update your app
4. **Real-time**: Uses Firestore listeners for instant updates

#### Setup Required:
- ✅ Firebase setup (above)
- ✅ Firestore enabled
- ✅ User must sign in with Google

#### No Additional Code Needed!
The integration is complete. Just:
1. User signs in with Google
2. User taps "Google Home" pill to link
3. Devices automatically sync

---

### 3. Google Assistant Integration

#### How It Works:
1. **Voice Recognition**: Uses device microphone
2. **Command Parsing**: Understands natural language
3. **Device Control**: Automatically toggles switches
4. **Examples**:
   - "Turn on living room light"
   - "Turn off fan"
   - "Switch on kitchen light"

#### Setup Required:
- ✅ Microphone permissions (handled automatically)
- ✅ Speech recognition library (already added)

#### Permissions (Auto-requested):
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice commands</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition for voice commands</string>
```

#### No Additional Code Needed!
Just ensure permissions are in manifest files.

---

### 4. MQTT Setup (For ESP32 Communication)

#### Default Configuration:
- **Broker**: `broker.hivemq.com` (public, free)
- **Port**: `1883`
- **Client ID**: `nebula_core_app`

#### To Use Custom MQTT Broker:
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String mqttBroker = 'your-broker.com';
static const int mqttPort = 1883;
```

#### ESP32 Setup:
1. Generate firmware code in app
2. Edit WiFi credentials in generated code
3. Upload to ESP32
4. ESP32 connects to MQTT broker
5. App automatically connects and syncs

---

### 5. Weather API (Optional)

Currently uses mock data. To add real weather:

1. Get API key from [OpenWeatherMap](https://openweathermap.org/api)
2. Edit `lib/providers/live_info_provider.dart`:
```dart
const apiKey = 'YOUR_API_KEY';
const city = 'YourCity';
```

Uncomment the API call code in `_loadWeather()` method.

---

## 🎯 Release Checklist

### Before Releasing:

#### Android:
- [ ] Add `google-services.json` to `android/app/`
- [ ] Update `build.gradle.kts` files (see above)
- [ ] Add microphone permission to `AndroidManifest.xml`
- [ ] Get SHA-1 fingerprint and add to Firebase
- [ ] Test Google Sign-In
- [ ] Test Google Assistant voice commands

#### iOS:
- [ ] Add `GoogleService-Info.plist` to `ios/Runner/`
- [ ] Update `Info.plist` with microphone permissions
- [ ] Run `pod install` in `ios/` directory
- [ ] Test on real device (simulator doesn't support microphone)

#### General:
- [ ] Test all features in Local mode
- [ ] Test Firebase connection
- [ ] Test Google Home sync
- [ ] Test Google Assistant
- [ ] Configure MQTT broker (if using custom)
- [ ] Set up weather API (optional)

---

## 🔧 How Each Feature Works

### 1. Firebase Authentication
```
User taps "Sign in with Google"
    ↓
AuthService.signInWithGoogle()
    ↓
Google Sign-In flow
    ↓
Firebase Auth creates user
    ↓
User authenticated ✅
```

### 2. Google Home Sync
```
User toggles switch
    ↓
SwitchProvider.toggleSwitch()
    ↓
MQTT publish (to ESP32)
    ↓
GoogleHomeService.syncDeviceToCloud()
    ↓
Firestore update
    ↓
Google Home app sees change ✅
```

### 3. Google Assistant
```
User taps Assistant pill
    ↓
GoogleAssistantDialog opens
    ↓
User taps "Start Listening"
    ↓
Speech recognition starts
    ↓
User says: "Turn on living room light"
    ↓
Command parsed
    ↓
Device found: "living room light"
    ↓
Action: "turn on"
    ↓
Switch toggled ✅
```

### 4. MQTT Communication
```
App toggles switch
    ↓
MQTTService.publish("nebula/switch/1/set", "ON")
    ↓
ESP32 receives message
    ↓
ESP32 turns on GPIO pin
    ↓
ESP32 publishes state: "nebula/switch/1/state", "ON"
    ↓
App receives update
    ↓
UI updates ✅
```

---

## 📱 What Users Need to Do

### For Users (End Users):
1. **Install app** from Play Store/App Store
2. **Sign in** with Google account
3. **Link Google Home** (optional, tap pill)
4. **Grant microphone permission** (for Assistant)
5. **Use the app!**

### For Developers (You):
1. **Set up Firebase** (one-time)
2. **Add config files** (google-services.json)
3. **Update build files** (gradle/podfile)
4. **Test** all features
5. **Release** to stores

---

## ⚠️ Important Notes

### Firebase is Required For:
- Google Sign-In
- Google Home sync
- Cloud device storage

### Firebase is NOT Required For:
- Local switch control
- MQTT communication
- ESP32 code generation
- Scheduling
- Voice feedback (TTS)
- UI/UX features

### The App Works in 3 Modes:
1. **Local Mode**: Everything works, no Firebase needed
2. **Cloud Mode**: Requires Firebase, syncs to cloud
3. **Hybrid Mode**: Local + Cloud sync

---

## 🚀 Quick Release Path

### Minimal Setup (Local Mode Only):
1. ✅ No Firebase needed
2. ✅ No Google services needed
3. ✅ Just build and release
4. ✅ Users can use all local features

### Full Setup (With Google Services):
1. ⚠️ Set up Firebase (30 minutes)
2. ⚠️ Add config files (5 minutes)
3. ⚠️ Update build files (10 minutes)
4. ✅ Test and release

---

## 📞 Support

If you encounter issues:
1. Check Firebase console for errors
2. Check device logs for permission issues
3. Verify MQTT broker connectivity
4. Test on real device (not emulator for microphone)

---

## ✅ Summary

**You DON'T need to write any code!**

Just:
1. Set up Firebase project
2. Add config files
3. Update build files
4. Release!

All the integration code is already written and working! 🎉

