#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     HiddenGems - Run on Physical iPhone                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if device is connected
DEVICE_COUNT=$(xcrun xctrace list devices 2>&1 | grep -i "iphone" | grep -v "Simulator" | wc -l)

if [ "$DEVICE_COUNT" -eq "0" ]; then
    echo "❌ No iPhone detected!"
    echo ""
    echo "Please:"
    echo "  1. Connect your iPhone via USB cable"
    echo "  2. Unlock your iPhone"
    echo "  3. Tap 'Trust' if prompted on iPhone"
    echo "  4. Run this script again"
    echo ""
    exit 1
fi

echo "✅ iPhone detected!"
echo ""

# Get device name
DEVICE_NAME=$(xcrun xctrace list devices 2>&1 | grep -i "iphone" | grep -v "Simulator" | head -1 | sed 's/ (.*//')

echo "📱 Device: $DEVICE_NAME"
echo ""
echo "🔨 Building for device..."
echo ""

cd /Users/tristankennedy/Downloads/recovery

# Build for device
xcodebuild \
    -project HiddenGems.xcodeproj \
    -scheme HiddenGems \
    -sdk iphoneos \
    -configuration Debug \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="Apple Development" \
    CODE_SIGN_STYLE="Automatic" \
    DEVELOPMENT_TEAM="$(security find-certificate -a -c "Apple Development" | grep "alis" | head -1 | sed 's/.*"\(.*\)".*/\1/' || echo '')" \
    clean build \
    2>&1 | grep -E "(BUILD|error:|warning:)" | tail -10

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "NEXT STEPS IN XCODE:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. In Xcode, select your iPhone from the device dropdown"
    echo "   (Top toolbar, next to HiddenGems scheme)"
    echo ""
    echo "2. Press ⌘R (Command + R) to install and run"
    echo ""
    echo "3. FIRST TIME ONLY - On your iPhone:"
    echo "   → Settings → General → VPN & Device Management"
    echo "   → Tap 'Tristan Kennedy (Personal Team)'"
    echo "   → Tap 'Trust'"
    echo ""
    echo "4. Launch HiddenGems from your iPhone home screen!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo ""
    echo "❌ Build failed. Trying alternative approach..."
    echo ""
    echo "Opening Xcode - please follow these steps:"
    echo ""
    echo "1. Select your iPhone in device dropdown"
    echo "2. Press ⌘R to build and run"
    echo "3. Trust certificate on iPhone if prompted"
    echo ""
    
    open HiddenGems.xcodeproj
fi

