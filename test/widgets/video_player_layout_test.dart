import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/video_player_controls_layout.dart';

/// 播放容器现在一律满宽，高度按「屏高 30%」和「按宽高比算」取小值。
/// 竖屏 9:16 视频不再把容器压到 135px，控制条有整屏宽度可用。
void main() {
  const phone = Size(360, 800);

  test('portrait video keeps a full-width container', () {
    // 360 / (9/16) = 640 > 屏高 30%(240)，所以高度封顶 240，宽度仍是 360。
    expect(playerAreaHeight(phone, 9 / 16), closeTo(240, 0.01));
    expect(needsCompactControls(phone.width), isFalse);
  });

  test('landscape video height is driven by width', () {
    expect(playerAreaHeight(phone, 16 / 9), closeTo(202.5, 0.01));
    expect(needsCompactControls(phone.width), isFalse);
  });

  test('narrow windows still fall back to compact controls', () {
    // 分屏 / 桌面窄窗口：标准条要 158px，比它窄就把导航键放进底部条。
    expect(needsCompactControls(140), isTrue);
    expect(compactNavIconSize(140), inInclusiveRange(12, 22));
  });
}
