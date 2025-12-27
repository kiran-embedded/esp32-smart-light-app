# 🔧 Troubleshooting Google Sign-In Issues

## ❌ Common Error: "Google Sign-In Failed"

If you're getting "Google Sign-In Failed" or "Login Failed", follow these steps:

---

## ✅ Step 1: Check Firebase Console Setup

### Enable Google Sign-In in Firebase:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **nebula-smartpowergrid**
3. Click **Authentication** → **Sign-in method**
4. Click **Google** provider
5. Toggle **Enable** to ON
6. Enter **Project support email**
7. Click **Save**

**⚠️ This is REQUIRED!** Without this, Google Sign-In won't work.

---

## ✅ Step 2: Add SHA-1 Fingerprint (CRITICAL!)

### Get Your SHA-1:

**For Debug (Testing):**
```bash
cd android
./gradlew signingReport
```

Look for:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**For Release (Production):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Add to Firebase:
1. Firebase Console → **Project Settings** (gear icon)
2. Scroll to **"Your apps"** section
3. Click your Android app: **com.iot.nebulacontroller**
4. Scroll to **"SHA certificate fingerprints"**
5. Click **"Add fingerprint"**
6. Paste your SHA-1
7. Click **Save**

**⚠️ Without SHA-1, Google Sign-In will ALWAYS fail!**

---

## ✅ Step 3: Verify google-services.json

### Check File Location:
```bash
ls -la android/app/google-services.json
```

Should show the file exists.

### Verify Package Name:
Open `android/app/google-services.json` and check:
- Package name should be: `com.iot.nebulacontroller`
- Should match your `android/app/build.gradle.kts` applicationId

---

## ✅ Step 4: Rebuild After Changes

**After adding SHA-1 or updating Firebase:**
```bash
flutter clean
flutter pub get
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**⚠️ You MUST rebuild after adding SHA-1!**

---

## ✅ Step 5: Check Error Messages

The app now shows detailed error messages:

### Common Errors:

**"Google Sign-In is not enabled in Firebase Console"**
- ✅ Enable Google Sign-In in Firebase Console (Step 1)

**"Check SHA-1 fingerprint in Firebase Console"**
- ✅ Add SHA-1 fingerprint (Step 2)
- ✅ Rebuild app

**"Firebase initialization failed"**
- ✅ Check google-services.json is in `android/app/`
- ✅ Verify file is valid JSON

**"Network error"**
- ✅ Check internet connection
- ✅ Check Firebase project is active

---

## 🔍 Debug Steps

### 1. Check Firebase Status in App:
- Tap "Check Firebase Status" button on login screen
- See detailed Firebase configuration status

### 2. Check Logs:
```bash
adb logcat | grep -i firebase
adb logcat | grep -i "google.*sign"
```

### 3. Test Firebase Connection:
- Open app
- Try to sign in
- Check error message (now shows detailed info)

---

## ✅ Quick Fix Checklist

- [ ] Google Sign-In enabled in Firebase Console
- [ ] SHA-1 fingerprint added to Firebase Console
- [ ] google-services.json in `android/app/`
- [ ] Package name matches: `com.iot.nebulacontroller`
- [ ] App rebuilt after adding SHA-1
- [ ] App reinstalled on device

---

## 🚀 After Fixing

1. **Rebuild:**
   ```bash
   flutter clean
   flutter build apk --release
   ```

2. **Reinstall:**
   ```bash
   adb uninstall com.iot.nebulacontroller
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Test:**
   - Open app
   - Tap "Sign in with Google"
   - Should work! ✅

---

## 📱 Use Local Mode (Temporary Workaround)

If you need to use the app while fixing Firebase:

1. The app works in **Local Mode** without Firebase
2. All local features work:
   - Switch controls
   - MQTT
   - Scheduling
   - ESP32 code generation
3. Just skip Google Sign-In for now

---

## 🎯 Most Common Issue

**90% of Google Sign-In failures are because:**
- ❌ SHA-1 fingerprint NOT added to Firebase
- ❌ Google Sign-In NOT enabled in Firebase Console

**Fix both and rebuild!** ✅

---

## ✅ Summary

1. Enable Google Sign-In in Firebase Console
2. Add SHA-1 fingerprint
3. Rebuild app
4. Reinstall
5. Test

**That's it!** 🎉

