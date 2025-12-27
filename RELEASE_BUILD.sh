#!/bin/bash

# NEBULA CORE - Release Build Script
# This script builds the production-ready release APK

echo "🚀 NEBULA CORE - Release Build"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Step 5: Build App Bundle (for Play Store)
echo -e "${YELLOW}📦 Step 5: Building App Bundle (for Play Store)...${NC}"
flutter build appbundle --release
echo ""

# Step 6: Show results
echo -e "${GREEN}✅ Build Complete!${NC}"
echo ""
echo "📱 Release APK location:"
echo "   build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "📦 App Bundle location:"
echo "   build/app/outputs/bundle/release/app-release.aab"
echo ""
echo -e "${GREEN}🎉 Your app is ready for release!${NC}"

