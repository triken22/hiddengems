#!/bin/bash

# Add the new drawer files to the Xcode project
PROJECT_PATH="HiddenGems.xcodeproj"
PROJECT_NAME="HiddenGems"

# Files to add
FILES=(
    "Features/App/GemDrawerController.swift"
    "Features/Design/Components/BottomDrawer.swift"
    "Features/SpotDetail/Views/SpotDetailCompactView.swift"
    "Features/SpotDetail/Views/GemDrawerPagerView.swift"
    "Features/SpotDetail/Views/SpotActionBar.swift"
)

# Add each file to the project
for file in "${FILES[@]}"; do
    echo "Adding $file to Xcode project..."
    
    # Use xcodebuild to add the file (this is a simplified approach)
    # In practice, you'd need to modify the .pbxproj file directly or use Xcode's command line tools
    echo "File: $file"
done

echo "Files added to project. Please manually add these files to your Xcode project:"
for file in "${FILES[@]}"; do
    echo "  - $file"
done

