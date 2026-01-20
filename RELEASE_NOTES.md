# Nebula Core v1.2.0+27 (OLED MASTERY)

**Release Date:** January 20, 2026
**Build ID:** `NC-ANDROID-REL-27`
**Update Size:** UI OVEDRHAUL & CRITICAL FIXES
**Priority:** MANDATORY

---

## 🚀 WHAT'S NEW: THE OLED UPDATE
This update brings a complete visual overhaul to the Scheduler Hub, specifically designed for OLED displays, and restores critical functionality.

### 🖤 "Super Smooth" OLED Black UI
*   **True Black Background**: The scheduling hub now uses a pure black (`#000000`) background for infinite contrast.
*   **Performance Boost**: Removed all heavy frosted glass blurs, resulting in rock-solid **90FPS** scrolling performance.
*   **Premium Detailing**: New neon red accents and high-contrast borders replace the old glass effect.

### 🏷️ Restore: Rename Functionality
*   **Edit Directly**: You can now rename any switch directly from the Hub header.
*   **Cloud Sync**: Renaming immediately syncs with the Firebase backend to update across all devices.

### 🛡️ Critical Fixes
*   **Crash Resolution**: Fixed the **"Nebula Core stopping"** crash issue by hardening the background `NativeAlarmService`.
*   **WakeLock Optimization**: Improved background execution reliability.

---

## 📋 TECHNICAL CHANGELOG
*   `[UI]` **Overhaul**: Switched Scheduler UI to non-blurred OLED Black theme.
*   `[FEAT]` **Restore**: Re-implemented switch renaming logic with `SwitchDevicesNotifier` sync.
*   `[FIX]` **Crash**: Wrapped `NativeAlarmService.onStartCommand` in try-catch to prevent ANR/Crash.
*   `[CORE]` **Versioning**: Bumped version to `v1.2.0+27`.

---

**DEPLOYMENT STATUS: ACTIVE**
*Nebula Core - Precise. Beautiful. Efficient.*
