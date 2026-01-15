# Firebase Production Setup Guide

Follow these steps to set up your own Firebase backend for the Nebula Core IoT application.

## 1. Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and follow the setup wizard.
3. Disable Google Analytics (optional but recommended for simple setups).

## 2. Register Android App
1. In the Project Overview, click the **Android** icon.
2. **Android package name**: `com.iot.nebulacontroller` (This MUST match exactly).
3. **App nickname**: `Nebula Core`.
4. **Debug signing certificate SHA-1**:
    - Open the Nebula Core app on your phone.
    - Go to the **Login Screen**.
    - Scroll down to find the **SHA-1** fingerprint.
    - Copy and paste it here.
5. Click **Register app**.

## 3. Enable Authentication
1. Go to **Build** -> **Authentication**.
2. Click **Get Started**.
3. Go to the **Sign-in method** tab.
4. Click **Add new provider** and select **Google**.
5. Enable it and provide your project support email.
6. Click **Save**.

## 4. Set up Realtime Database (RTDB)
1. Go to **Build** -> **Realtime Database**.
2. Click **Create Database**.
3. Choose a location (e.g., `us-central1` or `asia-southeast1`).
4. Select **Start in test mode** (Remember to update rules later in Step 8!).
5. Click **Enable**.

## 5. Get Web Client ID (Optional)
> [!TIP]
> If you use the **Easy Import** (Step 6), the Web Client ID will be extracted automatically!
1. Go to **Project Settings** (gear icon) -> **Service accounts**.
2. Under "Google Cloud Platform (GCP) service accounts", click the **Google Cloud Console** link.
3. In Google Cloud Console, go to **APIs & Services** -> **Credentials**.
4. Look for **OAuth 2.0 Client IDs**.
5. Find the **Web client (Auto-created by Google Service)**.
6. Copy the **Client ID** (it looks like `1234567-abc.apps.googleusercontent.com`).

## 6. Configure the Nebula Core App
### Method A: One-Click Easy Import (Recommended)
1. Launch the app and go to the **Production Setup** screen.
2. Click the **IMPORT GOOGLE-SERVICES.JSON** button.
3. Select the `google-services.json` file you downloaded in Step 2.
4. All fields (API Key, Project ID, App ID, etc.) will be automatically filled.
5. Click **INITIALIZE NEBULA**.

### Method B: Manual Configuration
1. Enter the following from your Firebase Settings:
    - **API Key**: Found in Project Settings -> General.
    - **Project ID**: Found in Project Settings -> General.
    - **Database URL**: Found in Realtime Database top bar.
    - **App ID**: Found in Project Settings -> General -> Your Apps.
    - **Messaging Sender ID**: Found in Project Settings -> Cloud Messaging.
    - **Google Web Client ID**: The ID you copied in Step 5.
2. Click **INITIALIZE NEBULA**.
3. Restart the app.

## 7. Flash your ESP32
1. Open the [firmware/esp32_nebula_controller.ino](firmware/esp32_nebula_controller.ino) file.
2. Replace `YOUR_FIREBASE_API_KEY` and `DATABASE_URL` with your values.
3. Upload to your ESP32.
4. The Serial Monitor will show your unique **Device ID** (derived from Chip ID).
5. Ensure the app and ESP32 are on the same Firebase project!

## 8. Professional Security Rules
To secure your Realtime Database, go to the **Rules** tab in Firebase Console and paste the following. This structure ensures specific access control for commands, telemetry, and relay names.

```json
{
  "rules": {
    "devices": {
      "$deviceId": {
        "commands": {
          ".read": true,
          ".write": true
        },
        "telemetry": {
          ".read": true,
          ".write": true
        },
        "relayNames": {
          ".read": true,
          ".write": true
        }
      }
    }
  }
}
```
