# Nebula Core v1.2.0+24 (PURE AUTOMATION)

**Release Date:** January 20, 2026
**Build ID:** `NC-ANDROID-REL-24`
**Update Size:** MAJOR UI & CORE OPTIMIZATION
**Priority:** CRITICAL FOR STABILITY

---

## 🚀 WHAT'S NEW: THE SCHEDULER & PERFORMANCE UPDATE
This update delivers a complete overhaul of the Scheduler UI, removes the legacy Geofencing engine to streamline performance, and fixes all visibility and reliability issues.

### 🎨 The All-New Scheduler UI
We have reimagined the automation experience with a focus on premium aesthetics and fluid performance:
*   **Dynamic Theme Engine**: No more "Light Blue." Every toggle, pill, and action now perfectly respects your active theme (e.g., Cyberpunk Neon, Deep Space).
*   **Fluid Performance**: Rewritten `ListView` architecture with `cacheExtent` optimization ensures 60fps scrolling, even with complex schedules.
*   **Micro-Interactions**: Added satisfying haptic feedback and "breathing" animations to edit modes and toggles.
*   **Visual Clarity**:
    *   **Action Pills**: Crystal clear ON/OFF states with high-contrast text.
    *   **Day Selectors**: Intuitive, touch-friendly day toggles.
    *   **Iconography**: Restored the missing spinning "Clock Icon" in the Switch Tab.

### ✂️ Geofencing Deprecation
To focus on core reliability and simpler automation, the **Geofencing Engine has been fully removed**:
*   **Leaner Core**: Removed `GeofenceHelper`, `GeofenceService`, and `BootReceiver` logic related to location tracking.
*   **Battery Life**: Significant improvement in background battery usage by eliminating constant location polling.
*   **Simplified Permissions**: The app no longer requires background location access, making the setup process faster and more privacy-focused.

### 🛠️ Core Improvements
*   **Notification Engine**: Schedules now trigger a local notification when they execute, giving you instant confirmation even when the app is closed.
*   **Background Reliability**: Reinforced `NativeAlarmService` to ensure schedules fire exactly on time, every time.
*   **Dependency Cleanup**: Removed unused packages (`geofence_service`) to reduce app size and build complexity.

---

## 📸 VISUAL UPGRADE
The new Scheduler UI is designed to feel like a native extension of your phone:
*   **Glassmorphism**: Subtle, theme-aware glass effects.
*   **Neon Glows**: Dynamic shadows that match your chosen accent color.
*   **Smooth Motion**: Staggered entry animations for a premium feel.

---

## 📋 TECHNICAL CHANGELOG
*   `[UI]` **Scheduler**: Replaced hardcoded colors with `Theme.of(context).primaryColor`.
*   `[UI]` **Performance**: Added `cacheExtent: 1000` to `SchedulerSettingsPopup` to fix scroll lag.
*   `[UI]` **Fix**: Restored visibility of the Clock Icon in the Switch Tab.
*   `[CORE]` **Cleanup**: Removed all Geofencing code from `MainActivity.kt` and `BootReceiver.kt`.
*   `[CORE]` **Update**: Bumped version to `v1.2.0+24`.

---

**DEPLOYMENT STATUS: ACTIVE**
*Nebula Core - Precise. Beautiful. Efficient.*
