import 'package:flutter/material.dart';

/// 播放区高度：宽度永远占满屏幕，高度取「屏高 30%」和「按宽高比算出的高度」
/// 里小的那个。
///
/// 以前是把 [AspectRatio] 塞进 `maxHeight: 屏高 * 0.3` 的约束里，竖屏 9:16
/// 视频在 360x800 屏上宽度只剩 135px，控制条按钮直接溢出；现在容器满宽，
/// 视频自己用 contain 居中留黑边，控制条有整屏宽度。
double playerAreaHeight(Size screen, double aspectRatio) {
  final byWidth = screen.width / aspectRatio;
  final maxHeight = screen.height * 0.3;
  return byWidth <= maxHeight ? byWidth : maxHeight;
}

/// 标准条：上一个/下一个/播放列表 3 个 34px 按钮 + 56px 播放键 = 158px。
double controlBarMinWidth({required bool compact}) =>
    compact ? 56 : 56 + 3 * 34;

bool needsCompactControls(double surfaceWidth) =>
    controlBarMinWidth(compact: false) > surfaceWidth;

/// 窄屏把三个导航按钮放进底部条，平分剩余宽度（扣掉 media_kit 的左 16 / 右 8
/// 外边距和全屏键按最宽 48 算），图标按分到的槽位缩小，所以按钮永远不会溢出。
double compactNavIconSize(double surfaceWidth) =>
    (((surfaceWidth - 24 - 48) / 3) * 0.8).clamp(12.0, 22.0);
