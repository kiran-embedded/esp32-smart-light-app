# 📸 App Screenshots & Visual Guide

This folder contains screenshots and visual assets for the Nebula Core project.

## 📁 Folder Structure

```
app_screenshots/
├── home_screen.png          # Main dashboard with switch grid
├── settings_screen.png      # Settings and configuration
├── firebase_setup.png       # Firebase setup screen
├── robo_assistant.png       # AI voice assistant
├── switch_control.png       # Switch tile interaction
├── telemetry_view.png       # Real-time telemetry display
├── login_screen.png         # Google Sign-In
└── splash_screen.png        # Cinematic splash screen
```

## 🎨 UI Features Showcased

### Home Screen
- Glassmorphic design with frosted glass effects
- Neon-bordered switch tiles with unique colors
- Real-time telemetry cards (voltage, current, power)
- Weather integration
- System status indicators

### Settings Screen
- Firebase configuration interface
- Device management
- Switch naming and customization
- Debug tools access

### Firebase Setup
- Dynamic credential input
- SHA-1/SHA-256 fingerprint display
- Step-by-step configuration guide

### Robo Assistant
- Voice control interface
- Animated waveform during speech
- Text-to-speech feedback

## 📷 How to Add Screenshots

### From Android Device (ADB)

1. **Take Screenshot**:
   ```bash
   # Take screenshot on device (Power + Volume Down)
   # Or use ADB
   adb shell screencap -p /sdcard/screenshot.png
   ```

2. **Pull to Computer**:
   ```bash
   adb pull /sdcard/screenshot.png app_screenshots/home_screen.png
   ```

3. **Clean up device**:
   ```bash
   adb shell rm /sdcard/screenshot.png
   ```

### From Emulator

1. Click the **Camera** icon in emulator toolbar
2. Save to `app_screenshots/` folder
3. Rename appropriately

### Batch Capture Script

```bash
#!/bin/bash
# Save as capture_screenshots.sh

echo "📸 Capturing Nebula Core Screenshots..."

# Array of screen names
screens=("home" "settings" "firebase_setup" "robo" "login" "splash")

for i in "${!screens[@]}"; do
    echo "Capture ${screens[$i]} screen and press Enter..."
    read
    adb shell screencap -p /sdcard/temp.png
    adb pull /sdcard/temp.png "app_screenshots/${screens[$i]}_screen.png"
    adb shell rm /sdcard/temp.png
    echo "✅ Saved ${screens[$i]}_screen.png"
done

echo "🎉 All screenshots captured!"
```

## 🖼️ Image Guidelines

### Requirements
- **Format**: PNG (preferred) or JPG
- **Resolution**: 1080x2400 (or device native)
- **Size**: < 500 KB per image (optimize if needed)
- **Naming**: Use snake_case (e.g., `home_screen.png`)

### Optimization

```bash
# Install ImageMagick
sudo apt install imagemagick

# Optimize images
for img in app_screenshots/*.png; do
    convert "$img" -resize 1080x2400 -quality 85 "$img"
done
```

## 📝 Usage in Documentation

### In README.md

```markdown
## 🎨 App Screenshots

<div align="center">

### Home Dashboard
![Home Screen](app_screenshots/home_screen.png)

### Settings & Configuration
![Settings](app_screenshots/settings_screen.png)

### AI Voice Assistant
![Robo Assistant](app_screenshots/robo_assistant.png)

</div>
```

### In GitHub Releases

Attach screenshots when creating releases to showcase new features.

## 🎬 Video Demos

For animated demonstrations:

1. **Record Screen**:
   ```bash
   adb shell screenrecord /sdcard/demo.mp4
   # Perform actions (max 3 minutes)
   # Ctrl+C to stop
   adb pull /sdcard/demo.mp4 app_screenshots/demo.mp4
   ```

2. **Convert to GIF** (for README):
   ```bash
   ffmpeg -i demo.mp4 -vf "fps=10,scale=320:-1:flags=lanczos" demo.gif
   ```

## 📊 Asset Checklist

- [ ] Home screen with all switches
- [ ] Settings screen
- [ ] Firebase setup flow
- [ ] Robo assistant in action
- [ ] Login screen
- [ ] Splash screen
- [ ] Switch tile interaction (ON/OFF states)
- [ ] Telemetry display
- [ ] Weather card
- [ ] Debug tools

## 🌟 Tips for Great Screenshots

1. **Clean State**: Clear notifications, full battery icon
2. **Demo Data**: Use realistic switch names and values
3. **Lighting**: Capture in dark mode for OLED effect
4. **Timing**: Capture during animations for dynamic feel
5. **Context**: Show real-world usage scenarios

---

**Note**: Screenshots are for documentation purposes only. Actual app appearance may vary based on device and configuration.
