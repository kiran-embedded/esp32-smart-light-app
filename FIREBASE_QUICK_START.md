# 🔥 Firebase Quick Start - 5 Minutes

## ⚡ Fast Setup Guide

Your project: **nebula-smartpowergrid**

---

## 🎯 3 Steps (5 Minutes)

### Step 1: Enable Google Sign-In (2 min)
1. Go to: https://console.firebase.google.com/
2. Select project: **nebula-smartpowergrid**
3. Click **Authentication** → **Sign-in method**
4. Click **Google** → Toggle **Enable** → **Save**

### Step 2: Enable Firestore (2 min)
1. Click **Firestore Database**
2. Click **Create Database**
3. Choose **Test mode** → Select location → **Enable**

### Step 3: Add SHA-1 (1 min)
1. Run: `cd android && ./gradlew signingReport`
2. Copy SHA-1 fingerprint
3. Go to **Project Settings** (gear icon)
4. Click your Android app → **Add fingerprint** → Paste SHA-1 → **Save**

---

## ✅ Done!

Your app is ready! Build and test:
```bash
flutter build apk --debug
```

---

## 📋 Full Details

See `FIREBASE_SETUP_STEPS.md` for complete guide.

