#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'HiddenGems.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group
main_group = project.main_group

# Find or create Features group
features_group = main_group['Features'] || main_group.new_group('Features')

# Files to add
files = {
  'Design' => [
    'Features/Design/Theme/Colors.swift',
    'Features/Design/Theme/Typography.swift',
    'Features/Design/Theme/Spacing.swift',
    'Features/Design/Theme/AppTheme.swift',
    'Features/Design/Components/RoundedImageView.swift',
    'Features/Design/Components/PillButton.swift',
    'Features/Design/Components/FloatingCard.swift',
    'Features/Design/Components/LoadingView.swift',
    'Features/Design/Components/SearchBarView.swift',
    'Features/Design/Components/CustomTabBar.swift'
  ],
  'SpotDetail' => [
    'Features/SpotDetail/Views/SpotDetailView.swift',
    'Features/SpotDetail/ViewModels/SpotDetailViewModel.swift'
  ],
  'CreateSpot' => [
    'Features/CreateSpot/Views/CreateSpotView.swift',
    'Features/CreateSpot/Views/ImagePicker.swift',
    'Features/CreateSpot/ViewModels/CreateSpotViewModel.swift'
  ],
  'Map' => [
    'Features/Map/Components/SpotMapMarker.swift'
  ],
  'Profile' => [
    'Features/Profile/Views/CollectionsView.swift'
  ]
}

files.each do |group_name, file_paths|
  group = features_group[group_name] || features_group.new_group(group_name)
  
  file_paths.each do |file_path|
    next if target.source_build_phase.files_references.map(&:path).include?(file_path)
    
    file_ref = group.new_reference(file_path)
    target.add_file_references([file_ref])
    puts "Added: #{file_path}"
  end
end

# Add individual files
home_group = features_group['Home']
if home_group
  views_group = home_group['Views'] || home_group.new_group('Views')
  file_ref = views_group.new_reference('Features/Home/Views/HomeView.swift')
  target.add_file_references([file_ref]) unless target.source_build_phase.files_references.map(&:path).include?('Features/Home/Views/HomeView.swift')
  puts "Added: Features/Home/Views/HomeView.swift"
end

app_group = features_group['App']
if app_group
  file_ref = app_group.new_reference('Features/App/MainAppView.swift')
  target.add_file_references([file_ref]) unless target.source_build_phase.files_references.map(&:path).include?('Features/App/MainAppView.swift')
  puts "Added: Features/App/MainAppView.swift"
end

# Add ImageCacheService
services_group = main_group['Services']
if services_group
  media_group = services_group['Media'] || services_group.new_group('Media')
  file_ref = media_group.new_reference('Services/Media/ImageCacheService.swift')
  target.add_file_references([file_ref]) unless target.source_build_phase.files_references.map(&:path).include?('Services/Media/ImageCacheService.swift')
  puts "Added: Services/Media/ImageCacheService.swift"
end

project.save
puts "\n✅ All files added to Xcode project!"
