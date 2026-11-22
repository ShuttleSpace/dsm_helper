---
name: iOS Runner "Cycle inside Runner" build error
description: Why Flutter iOS builds fail with a dependency cycle after adding the Share Extension, and where the fix lives
type: project
---

`ios/Runner.xcodeproj/project.pbxproj` must keep the `Embed App Extensions` copy phase (`DC26BFF125CFDEC50016C63F`) **before** the `Thin Binary` script phase (`3B06AD1E1E4923F5004D2608`). Otherwise Xcode reports `error: Cycle inside Runner; building could produce unreliable results.`

**Why:** `Thin Binary` declares `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` as an input and no outputs, so Xcode treats it as depending on the whole app bundle being assembled; the `Embed App Extensions` phase is what finishes assembling `Runner.app/PlugIns/Share Extension.appex`. If it runs after `Thin Binary` (and `[CP] Embed Pods Frameworks`), the two phases cannot be ordered. Known Flutter issue: flutter/flutter#135056.

**How to apply:** When this cycle appears, reorder the `buildPhases` array in the Runner native target so `Embed App Extensions` follows `Embed Frameworks` and precedes `Thin Binary`. Verify with `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -quiet build CODE_SIGNING_ALLOWED=NO` (exit 0); no need for a full `flutter run`.

**Related:** `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/AppDelegate.swift`, [[fluwx-ios-wechat-header-path]]
