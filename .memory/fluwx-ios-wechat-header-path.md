---
name: fluwx 5.4.1 iOS build needs WeChat XCFramework header search path
description: Why the iOS build fails with 'WXApi.h file not found' and where the fix lives
type: project
---

`fluwx 5.4.1` 的 Objective-C 源码用 `#import <WXApi.h>` 这种非 framework 限定的头文件导入；CocoaPods 1.16.2 为 `WechatOpenSDK-XCFramework` 只生成 `FRAMEWORK_SEARCH_PATHS`，不给 `fluwx` pod target 生成指向 XCFramework `Headers/` 的 `HEADER_SEARCH_PATHS`，所以 clang 找不到 `WXApi.h`。`ios/Podfile` 的 `post_install` 里针对 `target.name == 'fluwx'` 加入 `$(PODS_XCFRAMEWORKS_BUILD_DIR)/WechatOpenSDK-XCFramework/WechatOpenSDK.framework/Headers` 即可（slice 无关，Copy XCFrameworks 脚本在编译前已把对应 slice 拷入该目录），改完要重跑 `pod install`。

**Why:** 头文件实际存在（`ios/Pods/WechatOpenSDK-XCFramework/WechatOpenSDK.xcframework/.../WechatOpenSDK.framework/Headers/`），缺的是搜索路径；Podfile 里的清华镜像 source 与此无关（2.0.9 spec 与 trunk 完全一致）。

**How to apply:** iOS 再报 `WXApi.h` 未找到时，先查 `xcodebuild -project ios/Pods/Pods.xcodeproj -target fluwx -configuration Debug -sdk iphonesimulator -showBuildSettings` 的 `HEADER_SEARCH_PATHS`；快速复现用同一命令的 `build`（秒级，不必跑 12 分钟的 `flutter run`）。

**Related:** `ios/Podfile`
