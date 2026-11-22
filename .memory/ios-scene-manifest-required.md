---
name: iOS 27 simulator launch needs UIApplicationSceneManifest
description: Why the app SIGTRAPs on launch with the iOS 27 SDK and where the fix lives
type: project
---

Flutter 3.50 / iOS 27 SDK requires the scene-based UIKit lifecycle. `ios/Runner/Info.plist` must declare `UIApplicationSceneManifest` with `UISceneConfigurations` → `UIWindowSceneSessionRoleApplication` → `UISceneDelegateClassName`. This project uses `FlutterSceneDelegate` (the class shipped inside Flutter.framework) directly, so no SceneDelegate.swift or pbxproj edits are needed. Without the manifest, launch dies immediately with SIGTRAP(5) and UIKit logs: "Application failed to launch: UIScene life cycle is required for apps built with this SDK." (`_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`, UIApplication_RuntimeIssues.m:106).

**Why:** the app project predates Flutter's scene-lifecycle template (Flutter 3.50 `ios.tmpl/Runner/Info.plist.tmpl:29-47`); Xcode 26/iOS 27 enforces the manifest at runtime. The installed Flutter framework exports `_OBJC_CLASS_$_FlutterSceneDelegate`, and setting that class name in the manifest was proven to launch and render the login screen with plugins registered.

**How to apply:** when a simulator launch exits with SIGTRAP and no stderr, check `xcrun simctl spawn booted log show --last 2m --predicate 'process == "Runner"'` for the UIKit message before suspecting signing or dyld. To verify a fix quickly, rebuild with `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -quiet build` (no `CODE_SIGNING_ALLOWED=NO` override — that makes CocoaPods skip framework signing and creates a false "Library not loaded: @rpath/Ass.framework/Ass" dyld crash), then `xcrun simctl install/launch booted io.shuttle.garden`, check liveness with `xcrun simctl spawn booted launchctl list | grep shuttle`, and screenshot with `xcrun simctl io booted screenshot`.

**Related:** `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`, [[ios-runner-embed-phase-cycle]], [[fluwx-ios-wechat-header-path]]
