#!/bin/bash

# NEBULA CORE - Build and Install Script
# This script builds the app and installs it via ADB

echo "🚀 NEBULA CORE - Build and Install"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo -e "${YELLOW}📱 ADB not found. Installing ADB...${NC}"
    
    # Detect Linux distribution
    if [ -f /etc/debian_version ]; then
        echo "Installing ADB via apt..."
        sudo apt update
        sudo apt install -y android-tools-adb android-tools-fastboot
    elif [ -f /etc/arch-release ]; then
        echo "Installing ADB via pacman..."
        sudo pacman -S --noconfirm android-tools
    elif [ -f /etc/fedora-release ]; then
        echo "Installing ADB via dnf..."
        sudo dnf install -y android-tools
    else
        echo -e "${RED}❌ Could not detect package manager. Please install ADB manually:${NC}"
        echo "   Debian/Ubuntu: sudo apt install android-tools-adb"
        echo "   Arch: sudo pacman -S android-tools"
        echo "   Fedora: sudo dnf install android-tools"
        exit 1
    fi
    
    echo -e "${GREEN}✅ ADB installed!${NC}"
    echo ""
fi

# Check ADB version
echo -e "${BLUE}📱 ADB Version:${NC}"
adb version
echo ""

# Check if device is connected
echo -e "${YELLOW}🔍 Checking for connected devices...${NC}"
DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)

if [ "$DEVICES" -eq 0 ]; then
    echo -e "${RED}❌ No Android device detected!${NC}"
    echo ""
    echo "Please:"
    echo "1. Connect your Android device via USB"
    echo "2. Enable USB Debugging:"
    echo "   Settings → About Phone → Tap 'Build Number' 7 times"
    echo "   Settings → Developer Options → Enable 'USB Debugging'"
    echo "3. Accept the USB debugging prompt on your device"
    echo ""
    echo "Or use wireless ADB:"
    echo "  adb connect <device-ip>:5555"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Device detected!${NC}"
adb devices
echo ""

# Step 1: Clean
echo -e "${YELLOW}📦 Step 1: Cleaning build...${NC}"
flutter clean
echo ""

# Step 2: Get dependencies
echo -e "${YELLOW}📥 Step 2: Getting dependencies...${NC}"
flutter pub get
echo ""

# Step 3: Analyze code
echo -e "${YELLOW}🔍 Step 3: Analyzing code...${NC}"
flutter analyze
echo ""

# Step 4: Build release APK
echo -e "${YELLOW}🔨 Step 4: Building release APK...${NC}"
flutter build apk --release
echo ""

# Check if build was successful
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ Build failed! APK not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

# Step 5: Uninstall old version (if exists)
echo -e "${YELLOW}🗑️  Step 5: Uninstalling old version (if exists)...${NC}"
adb uninstall com.iot.nebulacontroller 2>/dev/null || true
echo ""

# Step 6: Install APK
echo -e "${YELLOW}📲 Step 6: Installing APK on device...${NC}"
adb install -r "$APK_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Installation successful!${NC}"
    echo ""
    echo -e "${BLUE}📱 App installed on device!${NC}"
    echo ""
    echo "You can now:"
    echo "1. Open the app from your device"
    echo "2. Or launch it via ADB:"
    echo "   adb shell am start -n com.iot.nebulacontroller/com.iot.nebulacontroller.MainActivity"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Installation failed!${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Device not authorized - Check USB debugging authorization"
    echo "2. Insufficient storage - Free up space on device"
    echo "3. App already installed - Try: adb uninstall com.iot.nebulacontroller"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Done!${NC}"


