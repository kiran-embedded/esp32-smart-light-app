# 🔍 Verify SHA-1 Configuration

## Your SHA-1 Fingerprint

You provided: `09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`

## ✅ How to Verify It's Correct

### 1. Get SHA-1 from Your Build:
```bash
cd android
./gradlew signingReport
```

Look for output like:
```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### 2. Format Check:
SHA-1 should be:
- 20 pairs of hex characters
- Separated by colons (:)
- Example: `AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD`

Your SHA-1: `09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`
✅ Format looks correct!

---

## 🔧 Steps to Fix

### Step 1: Verify SHA-1 in Firebase Console

1. Go to: https://console.firebase.google.com/
2. Select project: **nebula-smartpowergrid**
3. Click **Project Settings** (gear icon)
4. Scroll to **"Your apps"**
5. Click your Android app: **com.iot.nebulacontroller**
6. Scroll to **"SHA certificate fingerprints"**
7. **Check if your SHA-1 is listed:**
   - Should see: `09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`
   - If NOT there → Add it!
   - If it IS there → Continue to Step 2

### Step 2: Verify Google Sign-In is Enabled

1. Firebase Console → **Authentication**
2. Click **Sign-in method** tab
3. Check **Google** provider:
   - Should show **"Enabled"** (green)
   - If **"Disabled"** → Click it → Toggle **Enable** → **Save**

### Step 3: Verify Package Name Matches

**In Firebase Console:**
- Package name should be: `com.iot.nebulacontroller`

**In your app:**
- Check `android/app/build.gradle.kts`:
  - `applicationId = "com.iot.nebulacontroller"`

**They MUST match exactly!**

### Step 4: Rebuild After Adding SHA-1

**IMPORTANT:** After adding SHA-1, you MUST rebuild:

```bash
flutter clean
flutter pub get
flutter build apk --release
adb uninstall com.iot.nebulacontroller
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🐛 Common Issues

### Issue 1: SHA-1 Added But Not Working
**Cause:** App not rebuilt after adding SHA-1
**Fix:** Rebuild and reinstall (Step 4)

### Issue 2: Wrong SHA-1
**Cause:** Using release SHA-1 for debug build (or vice versa)
**Fix:** 
- For testing: Use debug SHA-1
- For production: Use release SHA-1
- Add BOTH to Firebase

### Issue 3: Package Name Mismatch
**Cause:** Package name in Firebase doesn't match app
**Fix:** Check both match exactly: `com.iot.nebulacontroller`

### Issue 4: Google Sign-In Not Enabled
**Cause:** Forgot to enable in Firebase Console
**Fix:** Enable it (Step 2)

---

## ✅ Complete Checklist

- [ ] SHA-1 added to Firebase Console
- [ ] SHA-1 format is correct (20 hex pairs with colons)
- [ ] Google Sign-In enabled in Firebase Console
- [ ] Package name matches: `com.iot.nebulacontroller`
- [ ] App rebuilt after adding SHA-1
- [ ] App reinstalled on device
- [ ] Internet connection working
- [ ] Firebase project is active

---

## 🔍 Debug: Check What Error You Get

The app now shows detailed errors. When you try to sign in:

1. **What error message appears?**
   - Write it down exactly

2. **Tap "Check Firebase Status" button**
   - See what's configured

3. **Check device logs:**
   ```bash
   adb logcat | grep -i "google\|firebase\|auth" | tail -30
   ```

---

## 🚀 Quick Test

After fixing everything:

1. Rebuild:
   ```bash
   flutter build apk --release
   ```

2. Reinstall:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

3. Test:
   - Open app
   - Try sign in
   - Should work! ✅

---

## 📞 Still Not Working?

If SHA-1 is added and Google Sign-In is enabled but still fails:

1. **Check Firebase Console:**
   - Is project active?
   - Is billing enabled? (if required)
   - Are there any errors shown?

2. **Check Device:**
   - Is Google Play Services installed?
   - Is device connected to internet?
   - Try on different device

3. **Check Logs:**
   ```bash
   adb logcat -c  # Clear logs
   # Try sign in
   adb logcat -d | grep -i error
   ```

---

## 🎯 Most Likely Issue

**Even if SHA-1 is added, if you didn't rebuild the app after adding it, it won't work!**

**Solution:** Always rebuild after adding SHA-1!

