# 🔥 Firebase Console Setup - Step by Step

## 📋 What You Need to Do in Firebase

Since you've already added `google-services.json`, here's what to configure in Firebase Console:

---

## 🚀 Step-by-Step Firebase Setup

### 1. Go to Firebase Console
👉 **https://console.firebase.google.com/**

### 2. Select Your Project
- Your project: **nebula-smartpowergrid**
- Project ID: `883218584898`

---

## ✅ Step 1: Enable Authentication (REQUIRED)

### Why:
- Allows Google Sign-In in your app
- Required for user authentication

### How:
1. In Firebase Console, click **"Authentication"** (left sidebar)
2. Click **"Get Started"** (if first time)
3. Click **"Sign-in method"** tab
4. Click **"Google"** provider
5. Toggle **"Enable"** to ON
6. Enter **Project support email** (your email)
7. Click **"Save"**

### ✅ Done!
Now users can sign in with Google in your app!

---

## ✅ Step 2: Enable Firestore Database (REQUIRED)

### Why:
- Stores device data in cloud
- Enables Google Home sync
- Multi-device support

### How:
1. In Firebase Console, click **"Firestore Database"** (left sidebar)
2. Click **"Create Database"**
3. Choose **"Start in test mode"** (for development)
   - ⚠️ For production, set up security rules later
4. Choose **Cloud Firestore location**
   - Recommended: `asia-southeast1` (closest to your region)
   - Or choose based on your users' location
5. Click **"Enable"**

### ✅ Done!
Your app can now sync data to cloud!

---

## ✅ Step 3: Add SHA-1 Fingerprint (REQUIRED for Android)

### Why:
- Required for Google Sign-In on Android
- Without this, Google Sign-In won't work

### How to Get SHA-1:

#### For Debug (Testing):
```bash
cd android
./gradlew signingReport
```

Look for:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

#### For Release (Production):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Or if you have a release keystore:
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

### Add to Firebase:
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll to **"Your apps"** section
3. Click on your **Android app** (`com.iot.nebulacontroller`)
4. Scroll to **"SHA certificate fingerprints"**
5. Click **"Add fingerprint"**
6. Paste your SHA-1
7. Click **"Save"**

### ✅ Done!
Google Sign-In will work on Android!

---

## ✅ Step 4: Set Up Firestore Security Rules (IMPORTANT)

### Why:
- Protects your data
- Controls who can read/write

### How:
1. Go to **Firestore Database**
2. Click **"Rules"** tab
3. Replace with this (for development):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Devices under user
      match /devices/{deviceId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

4. Click **"Publish"**

### ⚠️ For Production:
- Review and tighten security rules
- Add validation
- Restrict access based on user roles

### ✅ Done!
Your data is now protected!

---

## ✅ Step 5: Enable Cloud Messaging (OPTIONAL - For Future Push Notifications)

### Why:
- Send push notifications
- Notify users of device status changes

### How:
1. Go to **Cloud Messaging** (left sidebar)
2. Click **"Get Started"**
3. Follow setup wizard
4. (Optional) Set up server key for push notifications

### ⚠️ Not Required Now:
- Can be added later
- App works without it

---

## ✅ Step 6: Enable Analytics (OPTIONAL)

### Why:
- Track app usage
- Understand user behavior

### How:
1. Go to **Analytics** (left sidebar)
2. Click **"Get Started"**
3. Follow setup wizard

### ⚠️ Not Required:
- App works without it
- Can enable later

---

## 📋 Quick Checklist

### Required (Do These):
- [ ] ✅ Enable Authentication → Google Sign-In
- [ ] ✅ Enable Firestore Database
- [ ] ✅ Add SHA-1 Fingerprint (Android)
- [ ] ✅ Set Firestore Security Rules

### Optional (Can Do Later):
- [ ] Cloud Messaging (for push notifications)
- [ ] Analytics (for tracking)
- [ ] Storage (for file uploads)

---

## 🎯 Minimum Setup (5 Minutes)

**Just do these 3 things:**

1. **Enable Authentication** (2 min)
   - Authentication → Sign-in method → Enable Google

2. **Enable Firestore** (2 min)
   - Firestore Database → Create Database → Test mode

3. **Add SHA-1** (1 min)
   - Project Settings → Your Android app → Add SHA-1

**That's it!** Your app will work! 🎉

---

## 🔍 Verify Setup

### Check Authentication:
1. Go to **Authentication** → **Users** tab
2. Should be empty (users will appear after sign-in)

### Check Firestore:
1. Go to **Firestore Database** → **Data** tab
2. Should show empty database
3. Data will appear when app syncs

### Check SHA-1:
1. Go to **Project Settings** → **Your apps**
2. Check Android app has SHA-1 fingerprint

---

## 🚀 Test Your Setup

### After Setup:
1. Build your app: `flutter build apk --debug`
2. Install on device
3. Open app
4. Tap **"Sign in with Google"**
5. Should work! ✅

### If Google Sign-In Fails:
- Check SHA-1 is added correctly
- Verify Authentication is enabled
- Check internet connection
- Check Firebase project is correct

---

## 📱 What Happens After Setup

### When User Signs In:
1. User taps "Sign in with Google"
2. Firebase Authentication creates user account
3. User data stored in Firestore
4. App can sync devices to cloud

### When User Links Google Home:
1. User taps Google Home pill
2. Devices sync to Firestore
3. Google Home app can see devices
4. Bidirectional sync works

---

## ⚠️ Important Notes

### Development vs Production:

**Development (Now):**
- Use "Test mode" for Firestore
- Debug SHA-1 fingerprint
- Relaxed security rules

**Production (Before Release):**
- Set up production Firestore rules
- Add release SHA-1 fingerprint
- Tighten security rules
- Set up proper authentication

### Security:
- Never commit SHA-1 keys to public repos
- Keep Firebase config files secure
- Review security rules regularly
- Monitor Firebase usage

---

## 🎉 Summary

### What You Need to Do:

1. **Enable Google Sign-In** (2 min) ✅
2. **Enable Firestore** (2 min) ✅
3. **Add SHA-1 Fingerprint** (1 min) ✅
4. **Set Security Rules** (2 min) ✅

**Total Time: ~7 minutes**

### After Setup:
- ✅ Google Sign-In works
- ✅ Firestore sync works
- ✅ Google Home integration works
- ✅ Cloud storage works

**Your app is ready!** 🚀

---

## 📞 Need Help?

### Common Issues:

**"Google Sign-In not working":**
- Check SHA-1 is added
- Verify Authentication is enabled
- Check package name matches

**"Firestore permission denied":**
- Check security rules
- Verify user is authenticated
- Check user ID matches

**"Can't connect to Firebase":**
- Check internet connection
- Verify google-services.json is correct
- Check Firebase project is active

---

## ✅ You're All Set!

Once you complete these steps, your app will have:
- ✅ Google Sign-In
- ✅ Cloud storage
- ✅ Google Home sync
- ✅ Multi-device support

**Just follow the steps above and you're done!** 🎊

