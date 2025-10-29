#!/bin/bash

# HiddenGems - Quick Run Script
# This script builds and runs the app in the iOS Simulator

echo "╔════════════════════════════════════════════╗"
echo "║     HiddenGems - Build & Run Script       ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Configuration
SIMULATOR_NAME="iPhone 16 Pro"
BUNDLE_ID="com.example.HiddenGems"
PROJECT_PATH="/Users/tristankennedy/Downloads/recovery"

cd "$PROJECT_PATH"

echo "📱 Step 1: Checking simulator..."
# Boot simulator if not running
xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
open -a Simulator
sleep 2

echo "🔨 Step 2: Building app..."
xcodebuild -project HiddenGems.xcodeproj \
    -scheme HiddenGems \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    clean build \
    | grep -E "(BUILD|error:|warning:)" \
    || echo "   Building..."

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed! Check errors above."
    exit 1
fi

echo "📦 Step 3: Installing app..."
# Find the app bundle
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/HiddenGems*/Build/Products/Debug-iphonesimulator -name "HiddenGems.app" -type d 2>/dev/null | head -1)

if [ -n "$APP_PATH" ]; then
    xcrun simctl install "$SIMULATOR_NAME" "$APP_PATH"
    echo "✅ App installed!"
    
    echo "🚀 Step 4: Launching app..."
    xcrun simctl launch "$SIMULATOR_NAME" "$BUNDLE_ID"
    echo "✅ App launched!"
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║     HiddenGems is now running! 🎉         ║"
    echo "╚════════════════════════════════════════════╝"
else
    echo "❌ Could not find built app. Please check build output."
    exit 1
fi

