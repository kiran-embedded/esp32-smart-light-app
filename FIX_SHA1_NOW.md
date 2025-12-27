# 🚨 URGENT: Fix SHA-1 Now!

## ❌ You Added the WRONG SHA-1!

**What you added:** `09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`

**What you NEED:** `85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23`

---

## ⚡ Quick Fix (2 Minutes)

### 1. Go to Firebase Console
👉 https://console.firebase.google.com/
👉 Project: **nebula-smartpowergrid**
👉 **Project Settings** (gear icon)

### 2. Remove Wrong SHA-1
- Scroll to **"Your apps"**
- Click **com.iot.nebulacontroller**
- Find SHA-1: `09:94:38:48:0a:1b:97:20:6f:f9:78:4e:a6:7c:a7:30:34:3a:2c:20`
- **Delete it** (if it exists)

### 3. Add CORRECT SHA-1
- Click **"Add fingerprint"**
- Paste this EXACTLY:
  ```
  85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23
  ```
- Click **Save**

### 4. Verify Google Sign-In Enabled
- **Authentication** → **Sign-in method** → **Google** → Must be **Enabled**

### 5. Rebuild App
```bash
flutter clean
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 6. Test!
- Open app
- Sign in with Google
- **Should work now!** ✅

---

## 🎯 That's It!

The wrong SHA-1 was the problem. Add the correct one and rebuild!

**Correct SHA-1:** `85:C0:12:51:A7:41:F8:4D:A3:1A:18:50:EB:75:49:E9:DB:A7:75:23`

