#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HiddenGems.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Files to remove (duplicates with wrong paths)
duplicate_files = [
  'Features/Design/Features/Design/Theme/Colors.swift',
  'Features/Design/Features/Design/Theme/Typography.swift',
  'Features/Design/Features/Design/Theme/Spacing.swift',
  'Features/Design/Features/Design/Theme/AppTheme.swift',
  'Features/Design/Features/Design/Components/RoundedImageView.swift',
  'Features/Design/Features/Design/Components/PillButton.swift',
  'Features/Design/Features/Design/Components/FloatingCard.swift',
  'Features/Design/Features/Design/Components/LoadingView.swift',
  'Features/Design/Features/Design/Components/SearchBarView.swift',
  'Features/Design/Features/Design/Components/CustomTabBar.swift',
  'Features/SpotDetail/Features/SpotDetail/Views/SpotDetailView.swift',
  'Features/SpotDetail/Features/SpotDetail/ViewModels/SpotDetailViewModel.swift',
  'Features/CreateSpot/Features/CreateSpot/Views/CreateSpotView.swift',
  'Features/CreateSpot/Features/CreateSpot/Views/ImagePicker.swift',
  'Features/CreateSpot/Features/CreateSpot/ViewModels/CreateSpotViewModel.swift',
  'Features/Map/Features/Map/Components/SpotMapMarker.swift',
  'Features/Profile/Features/Profile/Views/CollectionsView.swift',
  'Features/Home/Views/Features/Home/Views/HomeView.swift',
  'Features/App/Features/App/MainAppView.swift',
  'Services/Media/Services/Media/ImageCacheService.swift'
]

puts "Removing duplicate file references..."

# Remove duplicate file references
duplicate_files.each do |file_path|
  # Find file references with this path
  file_refs = project.files.select { |file| file.path == file_path }
  
  file_refs.each do |file_ref|
    puts "Removing duplicate: #{file_path}"
    
    # Remove from target
    target.source_build_phase.remove_file_reference(file_ref)
    
    # Remove from project
    project.files.delete(file_ref)
  end
end

# Save the project
project.save

puts "Duplicate file references removed successfully!"

