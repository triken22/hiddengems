#!/usr/bin/env python3

import re

# Read the project file
with open('HiddenGems.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Define the correct file paths that should exist
correct_files = [
    'Features/Design/Theme/Colors.swift',
    'Features/Design/Theme/Typography.swift', 
    'Features/Design/Theme/Spacing.swift',
    'Features/Design/Theme/AppTheme.swift',
    'Features/Design/Components/RoundedImageView.swift',
    'Features/Design/Components/PillButton.swift',
    'Features/Design/Components/FloatingCard.swift',
    'Features/Design/Components/LoadingView.swift',
    'Features/Design/Components/SearchBarView.swift',
    'Features/Design/Components/CustomTabBar.swift',
    'Features/SpotDetail/Views/SpotDetailView.swift',
    'Features/SpotDetail/ViewModels/SpotDetailViewModel.swift',
    'Features/CreateSpot/Views/CreateSpotView.swift',
    'Features/CreateSpot/Views/ImagePicker.swift',
    'Features/CreateSpot/ViewModels/CreateSpotViewModel.swift',
    'Features/Map/Components/SpotMapMarker.swift',
    'Features/Profile/Views/CollectionsView.swift',
    'Features/Home/Views/HomeView.swift',
    'Features/App/MainAppView.swift',
    'Services/Media/ImageCacheService.swift'
]

# Define the incorrect duplicate paths that should be removed
duplicate_patterns = [
    r'Features/Design/Features/Design/',
    r'Features/SpotDetail/Features/SpotDetail/',
    r'Features/CreateSpot/Features/CreateSpot/',
    r'Features/Map/Features/Map/',
    r'Features/Profile/Features/Profile/',
    r'Features/Home/Views/Features/Home/Views/',
    r'Features/App/Features/App/',
    r'Services/Media/Services/Media/'
]

print("Removing duplicate file references...")

# Remove lines that contain duplicate paths
lines = content.split('\n')
filtered_lines = []

for line in lines:
    should_keep = True
    for pattern in duplicate_patterns:
        if pattern in line:
            print(f"Removing duplicate: {line.strip()}")
            should_keep = False
            break
    if should_keep:
        filtered_lines.append(line)

# Join the lines back
new_content = '\n'.join(filtered_lines)

# Write the fixed project file
with open('HiddenGems.xcodeproj/project.pbxproj', 'w') as f:
    f.write(new_content)

print("Duplicate file references removed successfully!")

