#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('HiddenGems.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Files that need to be added to the project
files_to_add = [
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
    'Features/Design/Components/BottomDrawer.swift',
    'Features/SpotDetail/Views/SpotDetailView.swift',
    'Features/SpotDetail/ViewModels/SpotDetailViewModel.swift',
    'Features/SpotDetail/Views/SpotDetailCompactView.swift',
    'Features/SpotDetail/Views/GemDrawerPagerView.swift',
    'Features/SpotDetail/Views/SpotActionBar.swift',
    'Features/CreateSpot/Views/CreateSpotView.swift',
    'Features/CreateSpot/Views/ImagePicker.swift',
    'Features/CreateSpot/ViewModels/CreateSpotViewModel.swift',
    'Features/Map/Components/SpotMapMarker.swift',
    'Features/Profile/Views/CollectionsView.swift',
    'Features/Home/Views/HomeView.swift',
    'Features/App/MainAppView.swift',
    'Features/App/GemDrawerController.swift',
    'Services/Media/ImageCacheService.swift'
]

# Generate unique IDs for new file references
def generate_id():
    return ''.join([str(uuid.uuid4()).replace('-', '').upper()[:24]])

# Find the PBXFileReference section
file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', content, re.DOTALL)
if not file_ref_section:
    print("Could not find PBXFileReference section")
    exit(1)

# Find the PBXBuildFile section
build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/(.*?)/\* End PBXBuildFile section \*/', content, re.DOTALL)
if not build_file_section:
    print("Could not find PBXBuildFile section")
    exit(1)

# Find the PBXSourcesBuildPhase section
sources_section = re.search(r'/\* Begin PBXSourcesBuildPhase section \*/(.*?)/\* End PBXSourcesBuildPhase section \*/', content, re.DOTALL)
if not sources_section:
    print("Could not find PBXSourcesBuildPhase section")
    exit(1)

print("Adding missing files to Xcode project...")

# Add file references
file_refs = []
build_files = []
sources_entries = []

for file_path in files_to_add:
    file_id = generate_id()
    build_id = generate_id()
    
    # Create file reference
    file_ref = f'\t\t{file_id} /* {file_path.split("/")[-1]} */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = {file_path.split("/")[-1]}; path = {file_path}; sourceTree = "<group>"; }};'
    file_refs.append(file_ref)
    
    # Create build file
    build_file = f'\t\t{build_id} /* {file_path.split("/")[-1]} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {file_path.split("/")[-1]} */; }};'
    build_files.append(build_file)
    
    # Create sources entry
    sources_entry = f'\t\t\t\t{build_id} /* {file_path.split("/")[-1]} in Sources */,'
    sources_entries.append(sources_entry)

# Insert file references
new_file_ref_section = file_ref_section.group(1) + '\n' + '\n'.join(file_refs) + '\n'
content = content.replace(file_ref_section.group(1), new_file_ref_section)

# Insert build files
new_build_file_section = build_file_section.group(1) + '\n' + '\n'.join(build_files) + '\n'
content = content.replace(build_file_section.group(1), new_build_file_section)

# Insert sources entries
sources_files_match = re.search(r'files = \((.*?)\);', sources_section.group(1), re.DOTALL)
if sources_files_match:
    new_sources_files = sources_files_match.group(1) + '\n' + '\n'.join(sources_entries) + '\n'
    content = content.replace(sources_files_match.group(1), new_sources_files)

# Write the updated project file
with open('HiddenGems.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"Added {len(files_to_add)} files to Xcode project successfully!")

