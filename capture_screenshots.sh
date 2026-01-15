#!/bin/bash

# Nebula Core - Screenshot Capture Script
# This script helps you capture all app screenshots systematically

echo "📸 Nebula Core Screenshot Capture Tool"
echo "======================================="
echo ""
echo "This script will guide you through capturing screenshots of all app screens."
echo "Make sure your device is connected via ADB and the app is running."
echo ""

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ Error: ADB not found. Please install Android SDK Platform Tools."
    echo "   Install: sudo apt install adb"
    exit 1
fi

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ Error: No device connected."
    echo "   Connect your device and enable USB debugging."
    exit 1
fi

echo "✅ Device connected!"
echo ""

# Create screenshots directory
mkdir -p app_screenshots

# Array of screens to capture
declare -A screens=(
    ["splash"]="Cinematic Splash Screen"
    ["login"]="Google Sign-In Screen"
    ["home"]="Home Dashboard (with all switches)"
    ["switch_on"]="Switch Tile - ON State"
    ["switch_off"]="Switch Tile - OFF State"
    ["telemetry"]="Telemetry Display (voltage/current)"
    ["weather"]="Weather Card"
    ["robo"]="Robo AI Assistant"
    ["settings"]="Settings Screen"
    ["firebase_setup"]="Firebase Setup Screen"
    ["debug"]="Debug Tools"
)

# Capture screenshots
counter=1
total=${#screens[@]}

for key in "${!screens[@]}"; do
    echo "[$counter/$total] ${screens[$key]}"
    echo "   Navigate to this screen and press ENTER to capture..."
    read
    
    # Capture screenshot
    adb shell screencap -p /sdcard/nebula_temp.png
    
    # Pull to computer
    adb pull /sdcard/nebula_temp.png "app_screenshots/${key}_screen.png" > /dev/null 2>&1
    
    # Clean up device
    adb shell rm /sdcard/nebula_temp.png
    
    if [ -f "app_screenshots/${key}_screen.png" ]; then
        echo "   ✅ Saved: ${key}_screen.png"
    else
        echo "   ❌ Failed to capture ${key}_screen.png"
    fi
    
    echo ""
    ((counter++))
done

echo "🎉 Screenshot capture complete!"
echo ""
echo "📁 Screenshots saved to: app_screenshots/"
echo ""

# Optional: Optimize images
read -p "Do you want to optimize images? (requires ImageMagick) [y/N]: " optimize

if [[ $optimize =~ ^[Yy]$ ]]; then
    if command -v convert &> /dev/null; then
        echo "🔧 Optimizing images..."
        for img in app_screenshots/*.png; do
            if [ -f "$img" ]; then
                convert "$img" -resize 1080x2400\> -quality 85 "$img"
                echo "   ✅ Optimized: $(basename "$img")"
            fi
        done
        echo "✅ Optimization complete!"
    else
        echo "❌ ImageMagick not found. Install with: sudo apt install imagemagick"
    fi
fi

echo ""
echo "📝 Next steps:"
echo "1. Review screenshots in app_screenshots/ folder"
echo "2. Add them to README.md"
echo "3. Commit and push to GitHub"
echo ""
echo "Happy documenting! 🚀"
