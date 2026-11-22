import 'package:flutter/material.dart';

/// 竖屏视频被压到屏高 30%，宽度可能只有 135px；控制条按钮不能全挤进去。
/// 这些纯函数给测试和播放器共用，避免复制约束数字。
double playerSurfaceWidth(Size screen, double aspectRatio) {
  final maxHeight = screen.height * 0.3;
  final byHeight = maxHeight * aspectRatio;
  return byHeight <= screen.width ? byHeight : screen.width;
}

/// 9:16 的竖屏缩略图/封面高度与屏高一致，宽度同上面的 30% 约束。
double coverSurfaceWidth(Size screen) => playerSurfaceWidth(screen, 9 / 16);

/// 标准条：上一个/下一个/播放列表 3 个 34px 按钮 + 56px 播放键 = 158px。
double controlBarMinWidth({required bool compact}) =>
    compact ? 56 : 56 + 3 * 34;

bool needsCompactControls(double surfaceWidth) =>
    controlBarMinWidth(compact: false) > surfaceWidth;

/// 底部条：media_kit 自带左 16 / 右 8 外边距，全屏键算 40px，窄屏再多一个 40px 的更多菜单。
/// 竖屏 9:16 视频在 360x800 屏上播放区只有 135px，三个 34px 按钮塞进去必然溢出。
double bottomBarMinWidth({required bool compact}) =>
    24 + 40 + (compact ? 40 : 0);

bool fitsCompactBottomBar(double surfaceWidth) =>
    bottomBarMinWidth(compact: true) <= surfaceWidth;
