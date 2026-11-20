❌ 仅移动端支持的依赖

1. battery_plus

- 问题: 仅支持 Android 和 iOS
- 补全依赖: 无需补全（桌面端通常没有电池）
- 建议: 在桌面端跳过电池相关功能

2. image_gallery_saver_plus

- 问题: 仅支持 Android 和 iOS
- 补全依赖: 无
- 建议: 桌面端可以使用 desktop_drop + 文件保存对话框

3. android_intent_plus

- 问题: 仅支持 Android
- 补全依赖: 无
- 建议: iOS 和桌面端使用 url_launcher 或平台特定实现

4. flutter_vibrate

- 问题: 仅支持 Android 和 iOS
- 补全依赖: 无
- 建议: 桌面端可以忽略震动功能

5. local_auth

- 问题: 仅支持 Android、iOS、macOS、Linux
- 问题: 不支持 Windows
- 补全依赖: 无
- 建议: Windows 使用 windows_hello 或跳过生物识别

6. device_info_plus

- 问题: 部分功能仅支持移动端
- 补全依赖: 已支持大部分平台

7. photo_manager

- 问题: 仅支持 Android 和 iOS
- 补全依赖:
  - 桌面端使用 file_picker + desktop_drop

8. flutter_sharing_intent

- 问题: 主要为移动端设计
- 补全依赖:
  - macOS 使用 share_plus (已支持)
  - Windows 使用 share_plus (已支持)
  - Linux 使用 share_plus (已支持)

9. fluwx (微信分享)

- 问题: 仅支持 Android 和 iOS
- 补全依赖: 无
- 建议: 桌面端跳过微信分享

10. background_downloader

- 问题: 部分功能仅支持移动端
- 补全依赖: 已支持大部分平台

11. media_kit_libs_video

- 问题: 需要平台特定实现
- 补全依赖:
  - macOS: 已包含
  - Windows: 需要额外安装
  - Linux: 需要额外安装

12. permission_handler

- 问题: 部分权限仅支持移动端
- 补全依赖: 已支持大部分平台

✅ 已跨平台支持的依赖

- dio、oktoast、package_info_plus、extended_image、cool_ui
- path_provider、fl_chart、file_picker_pro、open_filex
- flutter_html、wave、modal_bottom_sheet、url_launcher
- connectivity_plus、code_editor、flutter_highlight
- syncfusion_flutter_pdfviewer、wechat_assets_picker、xml2json
- dartssh2、xterm、webview_flutter、simple_logger
- extended_text、rxdart、flutter_floating、path
- signals、signals_flutter、media_kit、media_kit_video

📝 推荐的补全依赖清单

# 添加到 dependencies:

# 桌面端文件拖拽（替代 photo_manager 的桌面功能）

desktop_drop: ^0.5.0

# 桌面端分享（已包含在 share_plus 中，但确保最新版本）

share_plus: ^10.0.0

# Windows Hello（替代 local_auth 的 Windows 功能）

windows_hello: ^0.0.1

# 桌面端媒体播放器支持

media_kit_libs_windows_video: ^1.0.7
media_kit_libs_linux: ^1.0.7

# 桌面端通知

local_notifier: ^0.1.5

🎯 主要限制

1.  微信分享 (fluwx): 无法在桌面端实现
2.  图片保存到相册 (image_gallery_saver_plus): 桌面端无相册概念
3.  震动 (flutter_vibrate): 桌面端无震动硬件
4.  电池 (battery_plus): 桌面端通常不需要

✦ 总结: 大部分核心依赖已支持跨平台，主要问题在于移动端特定功能（相册、微信、震动、生物识别）在桌面端无法直接实现，需要使用替代方案或跳过这些功能。

```dart
 if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
```

```sh
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name                             Current              Upgradable           Resolvable           Latest

direct dependencies:
android_intent_plus                      *5.3.0               *5.3.0               6.0.0                6.0.0
background_downloader                    *8.9.5               *8.9.5               9.5.2                9.5.2
connectivity_plus                        *6.1.2               *6.1.2               7.0.0                7.0.0
device_info_plus                         *11.2.2              *11.2.2              12.3.0               12.3.0
extended_image                           *9.1.0               *9.1.0               10.0.1               10.0.1
fl_chart                                 *0.70.2              *0.70.2              1.1.1                1.1.1
flutter_floating                         *1.1.2               *1.1.2               2.0.2                2.0.2
fluwx                                    *5.4.1               *5.4.1               5.7.5                5.7.5
html                                     *0.15.5              *0.15.5              0.15.6               0.15.6
local_auth                               *2.3.0               *2.3.0               3.0.0                3.0.0
package_info_plus                        *8.2.0               *8.2.0               9.0.0                9.0.0
permission_handler                       *11.3.1              *11.3.1              12.0.1               12.0.1
photo_manager                            *3.6.4               *3.6.4               3.8.3                3.8.3
syncfusion_flutter_pdfviewer             *31.1.21             *31.1.21             32.2.3               32.2.3
webview_flutter                          *4.10.0              *4.10.0              4.13.1               4.13.1
xml2json                                 *6.2.6               *6.2.6               6.2.7                6.2.7

dev_dependencies:
flutter_lints                            *3.0.2               *3.0.2               6.0.0                6.0.0

transitive dependencies:
back_button_interceptor                  *6.0.0               *6.0.0               *6.0.0               8.0.4
characters                               *1.4.0               *1.4.0               *1.4.0               1.4.1
dbus                                     *0.7.11              0.7.12               0.7.12               0.7.12
extended_image_library                   *4.0.6               *4.0.6               5.0.1                5.0.1
ffi                                      *2.0.1 (overridden)  *2.0.1 (overridden)  *2.0.1 (overridden)  2.1.5 (overridden)
local_auth_android                       *1.0.56              *1.0.56              2.0.4                2.0.4
local_auth_darwin                        *1.6.1               *1.6.1               2.0.1                2.0.1
local_auth_windows                       *1.0.11              *1.0.11              2.0.1                2.0.1
matcher                                  *0.12.17             *0.12.17             *0.12.17             0.12.18
material_color_utilities                 *0.11.1              *0.11.1              *0.11.1              0.13.0
meta                                     *1.17.0              *1.17.0              *1.17.0              1.18.1
path_provider_foundation                 *2.5.1               *2.5.1               *2.5.1               2.6.0
permission_handler_android               *12.1.0              *12.1.0              13.0.1               13.0.1
pointycastle                             *3.9.1               *3.9.1               *3.9.1               4.0.0
source_span                              *1.10.1              1.10.2               1.10.2               1.10.2
syncfusion_flutter_core                  *31.2.18             *31.2.18             32.2.3               32.2.3
syncfusion_flutter_pdf                   *31.2.18             *31.2.18             32.2.3               32.2.3
syncfusion_flutter_signaturepad          *31.2.18             *31.2.18             32.2.3               32.2.3
syncfusion_pdfviewer_linux               *31.2.18             *31.2.18             32.2.3               32.2.3
syncfusion_pdfviewer_macos               *31.2.18             *31.2.18             32.2.3               32.2.3
syncfusion_pdfviewer_platform_interface  *31.2.18             *31.2.18             32.2.3               32.2.3
syncfusion_pdfviewer_web                 *31.2.18             *31.2.18             32.2.3               32.2.3
syncfusion_pdfviewer_windows             *31.2.18             *31.2.18             32.2.3               32.2.3
test_api                                 *0.7.7               *0.7.7               *0.7.7               0.7.9
video_player_avfoundation                *2.9.0               2.9.1                2.9.1                2.9.1
wakelock_plus                            *1.3.3               *1.3.3               1.4.0                1.4.0
win32_registry                           *1.1.5               *1.1.5               2.1.0                2.1.0

transitive dev_dependencies:
lints                                    *3.0.0               *3.0.0               6.1.0                6.1.0

3 upgradable dependencies are locked (in pubspec.lock) to older versions.
To update these dependencies, use `flutter pub upgrade`.

33  dependencies are constrained to versions that are older than a resolvable version.
To update these dependencies, edit pubspec.yaml, or run `flutter pub upgrade --major-versions`.
```
