#!/bin/bash

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  ENABLING AIRBNB-STYLE REDESIGN - PLEASE FOLLOW      ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Xcode should now be open. Please follow these steps:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Open Finder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Open Finder to the project directory
open -R "/Users/tristankennedy/Downloads/recovery/Features/Design"

echo "✓ Finder opened to Features folder"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: In Xcode, find 'Features' folder (left panel)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: From Finder, DRAG these 5 folders into Xcode:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Design        (drag onto 'Features' in Xcode)"
echo "  2. SpotDetail    (drag onto 'Features' in Xcode)"
echo "  3. CreateSpot    (drag onto 'Features' in Xcode)"  
echo "  4. Map           (drag onto 'Features' in Xcode)"
echo "  5. Profile       (drag onto 'Features' in Xcode)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: When dialog appears:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ✓ Check: 'Copy items if needed'"
echo "  ✓ Select: 'Create groups'"
echo "  ✓ Check: Add to targets: 'HiddenGems'"
echo "  ✓ Click 'Finish'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Add 2 more individual files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  a) Drag 'Home/Views' folder → onto 'Features/Home'"
echo "  b) Drag 'App/MainAppView.swift' → onto 'Features/App'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: Enable the new UI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Once you confirm files are added, press ENTER here..."
read -p ""

# Update the app entry point
sed -i '' 's/HomeTabView()/MainAppView()/g' "/Users/tristankennedy/Downloads/recovery/App/HiddenGemsApp.swift"

# Add createSpotViewModel method
cat > /tmp/add_method.swift << 'SWIFT'
    
    func createSpotViewModel() -> CreateSpotViewModel {
        CreateSpotViewModel(spotRepository: spotRepository,
                           mediaService: mediaService,
                           aiService: aiService,
                           locationService: locationService)
    }
SWIFT

# Insert the method before onAppear
perl -i -pe 'BEGIN{undef $/;} s/    func onAppear\(\)/`cat /tmp/add_method.swift`\n    func onAppear()/smg' "/Users/tristankennedy/Downloads/recovery/Features/Home/HomeViewModel.swift"

echo ""
echo "✓ Code updated to use new UI!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FINAL STEP: Build & Run in Xcode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Press ⌘B to build"
echo "  Press ⌘R to run"
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  You should now see the Airbnb-style design! 🎉      ║"
echo "╚═══════════════════════════════════════════════════════╝"

