# Nebula Core v1.2.0+30 (ULTIMATE PRECISION)

**Release Date:** January 20, 2026
**Build ID:** `NC-ANDROID-REL-30`
**Update Size:** UI REFINEMENT & VISIBILITY OVERHAUL
**Priority:** RECOMMENDED

---

## 🚀 WHAT'S NEW: THE VISIBILITY UPDATE
This release brings the Automation Hub to perfection with OLED-optimized visuals, enhanced visibility, and unique visual identifiers for each schedule.

### 🖤 OLED Black UI (Hardcoded)
*   **Pure Black Background**: Hardcoded `Colors.black` - no longer affected by theme changes
*   **Zero Blur**: Removed all blur effects for rock-solid 90FPS performance
*   **Premium Contrast**: High-contrast borders and text for maximum readability

### 🏷️ Device Rename Functionality
*   **Edit from Hub**: Tap the Edit icon in the Automation Hub header to rename any device
*   **Firebase Sync**: Name changes instantly sync across all devices via Firebase
*   **Persistent**: Renamed devices maintain their custom names across app restarts

### 🎨 Unique Clock Colors
*   **Visual Identity**: Each schedule now has a unique vibrant clock icon color
*   **Color Hash**: Colors are deterministically generated from schedule ID
*   **Easy Recognition**: Quickly identify schedules at a glance by their color

### ⚪ Enhanced Visibility
*   **Bright AM/PM**: Changed from grey to white for better readability
*   **High-Contrast Pills**: ON pills now use white, OFF pills use red
*   **Monochrome Border**: Create Schedule button features elegant white/grey dot-moving animation

### 🛡️ Stability Improvements
*   **Crash Fix**: Hardened `NativeAlarmService` with comprehensive error handling
*   **WakeLock Optimization**: Improved background task reliability

---

## 📋 TECHNICAL CHANGELOG
*   `[UI]` **Background**: Hardcoded OLED black background (no theme dependency)
*   `[UI]` **Clock Icons**: Unique HSV-based color per schedule ID
*   `[UI]` **Text**: Brightened AM/PM text from grey to white
*   `[UI]` **Pills**: Changed ON/OFF pills to white/red for better contrast
*   `[UI]` **Border**: Updated Create Schedule button to white/grey gradient
*   `[FEAT]` **Rename**: Restored device renaming with Firebase sync
*   `[FIX]` **Crash**: Added try-catch wrapper in `NativeAlarmService.onStartCommand`
*   `[PERF]` **Blur**: Removed all blur effects for 90FPS smoothness
*   `[CORE]` **Version**: Bumped to `v1.2.0+30`

---

**DEPLOYMENT STATUS: ACTIVE**
*Nebula Core - Precise. Beautiful. Efficient.*
