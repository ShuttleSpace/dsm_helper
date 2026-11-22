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
    compact ? 56 + 34 : 56 + 3 * 34;

bool needsCompactControls(double surfaceWidth) =>
    controlBarMinWidth(compact: false) > surfaceWidth;
