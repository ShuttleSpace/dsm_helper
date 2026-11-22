import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/video_player_controls_layout.dart';

void main() {
  test('portrait video surface is too narrow for the standard control bar', () {
    final width = playerSurfaceWidth(const Size(360, 800), 9 / 16);
    expect(width, closeTo(135, 0.01));
    expect(needsCompactControls(width), isTrue);
    // 标准条：3 个 34px 小按钮 + 56px 播放键 = 158px，135px 容器溢出 22px。
    expect(controlBarMinWidth(compact: false), 158.0);
  });

  test('compact control bar fits a portrait video surface', () {
    final width = playerSurfaceWidth(const Size(360, 800), 9 / 16);
    expect(controlBarMinWidth(compact: true), lessThanOrEqualTo(width));
  });

  test('landscape video keeps the standard control bar', () {
    final width = playerSurfaceWidth(const Size(360, 800), 16 / 9);
    expect(width, 360.0);
    expect(needsCompactControls(width), isFalse);
  });
}
