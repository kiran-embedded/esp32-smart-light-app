# ⚡ Quick Fix: Google Sign-In Failed

## 🎯 Most Likely Issues (90% of cases)

### Issue 1: SHA-1 Fingerprint Missing ⚠️
**This is the #1 cause of Google Sign-In failures!**

**Fix:**
1. Get SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Copy the SHA1 value
3. Go to Firebase Console → Project Settings → Your Android App
4. Add SHA-1 fingerprint
5. **Rebuild app:**
   ```bash
   flutter clean
   flutter build apk --release
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

### Issue 2: Google Sign-In Not Enabled ⚠️
**This is the #2 cause!**

**Fix:**
1. Firebase Console → Authentication → Sign-in method
2. Click **Google** → Toggle **Enable** → **Save**
3. No rebuild needed, just try again

---

## 🔍 Check What's Wrong

### In the App:
1. Try to sign in
2. **New:** Error message now shows detailed info!
3. Tap **"Check Firebase Status"** button
4. See exactly what's wrong

### Common Error Messages:

**"Google Sign-In is not enabled in Firebase Console"**
→ Enable it in Firebase Console

**"Check SHA-1 fingerprint in Firebase Console"**
→ Add SHA-1 and rebuild

**"Firebase initialization failed"**
→ Check google-services.json file

---

## ✅ Quick Checklist

- [ ] Google Sign-In enabled in Firebase Console?
- [ ] SHA-1 fingerprint added to Firebase?
- [ ] App rebuilt after adding SHA-1?
- [ ] google-services.json in android/app/?

---

## 🚀 After Fixing

1. Rebuild:
   ```bash
   flutter build apk --release
   ```

2. Reinstall:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

3. Test again!

---

## 📱 Use App Without Sign-In (Temporary)

The app works in **Local Mode** without Google Sign-In:
- All switches work
- MQTT works
- Scheduling works
- Everything except cloud sync

Just skip sign-in for now!

---

## 🎯 Most Common Fix

**90% of the time, it's missing SHA-1:**

1. Get SHA-1: `cd android && ./gradlew signingReport`
2. Add to Firebase Console
3. Rebuild app
4. Done! ✅

See `TROUBLESHOOTING_GOOGLE_SIGNIN.md` for full guide.

