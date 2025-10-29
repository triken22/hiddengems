# Xcode Project Setup Instructions

## ⚠️ Important: Add New Files to Xcode

The redesign created **21 new Swift files** that need to be added to your Xcode project before it will compile.

---

## 📋 Quick Setup (Recommended)

### Option 1: Drag & Drop (Easiest)

1. **Open Xcode**
   - Double-click `HiddenGems.xcodeproj`

2. **Open Finder**
   - Navigate to `/Users/tristankennedy/Downloads/recovery`
   - Keep both Xcode and Finder windows visible

3. **Drag folders into Xcode**
   - From Finder, drag these folders into the Xcode Project Navigator:
     - `Features/Design` → into Features folder
     - `Features/SpotDetail` → into Features folder  
     - `Features/CreateSpot` → into Features folder
     - `Features/Map` → into Features folder
     - `Features/Profile` → into Features folder
     - `Features/Home/Views` → into Features/Home folder
     - `Services/Media/ImageCacheService.swift` → into Services folder

4. **Important:** In the dialog that appears:
   - ✅ Check "Copy items if needed"
   - ✅ Select "Create groups"
   - ✅ Add to targets: "HiddenGems"
   - Click "Finish"

5. **Add individual file**
   - Drag `Features/App/MainAppView.swift` into Features/App folder

6. **Build the project**
   - Press `⌘B` or Product → Build

---

### Option 2: Add Files Menu

1. **Open Xcode** 
   - Double-click `HiddenGems.xcodeproj`

2. **Add Design System**
   - Right-click on "Features" folder in Project Navigator
   - Select "Add Files to HiddenGems..."
   - Navigate to and select `Features/Design` folder
   - ✅ Check "Copy items if needed"
   - ✅ Select "Create groups"  
   - ✅ Add to targets: "HiddenGems"
   - Click "Add"

3. **Repeat for each folder:**
   - `Features/SpotDetail`
   - `Features/CreateSpot`
   - `Features/Map`
   - `Features/Profile`
   - `Features/Home/Views`

4. **Add individual files:**
   - Right-click "Features/App"
   - Add Files → Select `MainAppView.swift`
   - Right-click "Services"
   - Add Files → Navigate to `Services/Media/ImageCacheService.swift`

5. **Build**
   - Press `⌘B`

---

## ✅ Verification Checklist

After adding files, verify in Xcode Project Navigator:

### Features/Design/
- ✅ Theme/
  - Colors.swift
  - Typography.swift
  - Spacing.swift
  - AppTheme.swift
- ✅ Components/
  - RoundedImageView.swift
  - PillButton.swift
  - FloatingCard.swift
  - LoadingView.swift
  - SearchBarView.swift
  - CustomTabBar.swift

### Features/Home/
- ✅ Views/
  - HomeView.swift

### Features/App/
- ✅ MainAppView.swift

### Features/SpotDetail/
- ✅ Views/
  - SpotDetailView.swift
- ✅ ViewModels/
  - SpotDetailViewModel.swift

### Features/CreateSpot/
- ✅ Views/
  - CreateSpotView.swift
  - ImagePicker.swift
- ✅ ViewModels/
  - CreateSpotViewModel.swift

### Features/Map/
- ✅ Components/
  - SpotMapMarker.swift

### Features/Profile/
- ✅ Views/
  - CollectionsView.swift

### Services/Media/
- ✅ ImageCacheService.swift

---

## 🔧 Troubleshooting

### "Cannot find type 'CreateSpotViewModel' in scope"
**Solution:** CreateSpotViewModel.swift is not added to the project
- Add `Features/CreateSpot` folder to project

### Build errors about missing types
**Solution:** Make sure all files are added to the "HiddenGems" target
- Select each file in Project Navigator
- Check File Inspector (⌘⌥1)
- Verify "Target Membership" includes "HiddenGems"

### Files appear in navigator but still get errors
**Solution:** Clean build folder and rebuild
- Product → Clean Build Folder (⌘⇧K)
- Product → Build (⌘B)

### "Update to recommended settings" warning
**Solution:** Click the warning and select "Perform Changes"

---

## 🚀 After Setup

Once all files are added and the project builds successfully:

1. **Run the app** (⌘R)
2. **Test main features:**
   - Browse spots on home feed
   - Search and filter
   - View spot details
   - Check map view
   - Try creating a new spot
   - View profile

3. **Enjoy the redesign!** 🎉

---

## 📝 Notes

- All 21 new files are already created in the file system
- They just need to be added to the Xcode project
- This is a one-time setup step
- After setup, the app will compile and run normally

---

## 💡 Tips

- **Keep backups:** The original files are preserved
- **Git commit:** Consider committing before testing
- **Simulator:** Test on iOS 17+ simulator for best results
- **Performance:** Image caching works best on device

---

Need help? Check `REDESIGN_SUMMARY.md` for full documentation!

