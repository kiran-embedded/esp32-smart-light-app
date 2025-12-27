# ⚠️ SHA-1 MISMATCH FOUND!

## 🔍 The Problem

**You added:** `09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`

**But your actual SHA-1 is:** `85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23`

**These are DIFFERENT!** That's why Google Sign-In is failing!

---

## ✅ THE FIX

### Step 1: Add the CORRECT SHA-1 to Firebase

**Correct SHA-1 to add:**
```
85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23
```

**How to add:**
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select project: **nebula-smartpowergrid**
3. Click **Project Settings** (gear icon)
4. Scroll to **"Your apps"**
5. Click your Android app: **com.iot.nebulacontroller**
6. Scroll to **"SHA certificate fingerprints"**
7. **Remove the old one** (if it's wrong)
8. Click **"Add fingerprint"**
9. Paste: `85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23`
10. Click **Save**

### Step 2: Verify Google Sign-In is Enabled

1. Firebase Console → **Authentication**
2. Click **Sign-in method** tab
3. Check **Google**:
   - Must show **"Enabled"** (green)
   - If disabled → Enable it!

### Step 3: Rebuild App (CRITICAL!)

**After adding correct SHA-1, you MUST rebuild:**

```bash
cd /home/kirancybergrid/nebula_core
flutter clean
flutter pub get
flutter build apk --release
adb uninstall com.iot.nebulacontroller
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎯 Why This Happened

The SHA-1 you added (`09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`) might be:
- From a different keystore
- From google-services.json certificate_hash (that's different!)
- From a release build (but you're using debug)

**The actual debug SHA-1 is:** `85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23`

---

## ✅ Quick Fix Steps

1. **Add correct SHA-1 to Firebase:**
   ```
   85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23
   ```

2. **Enable Google Sign-In** (if not already)

3. **Rebuild app:**
   ```bash
   flutter build apk --release
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Test!** Should work now! ✅

---

## 📝 Summary

- ❌ Wrong SHA-1 in Firebase: `09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`
- ✅ Correct SHA-1: `85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23`
- ✅ Add correct one → Rebuild → Done!

**This will fix your Google Sign-In!** 🎉

