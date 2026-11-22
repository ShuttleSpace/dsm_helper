import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/video_compact_nav_bar.dart';
import 'package:garden/widgets/video_player_controls_layout.dart';

/// media_kit 底部条：左右外边距 16/8，里面是自定义按钮 + 全屏键。
/// 竖屏 9:16 视频在 360x800 屏上播放区只有 135px，固定宽度按钮会溢出，
/// 所以三个导航按钮用 Expanded 平分，图标跟着缩。
void main() {
  const portraitScreen = Size(360, 800);
  final surface = playerSurfaceWidth(portraitScreen, 9 / 16);
  final iconSize = compactNavIconSize(surface);

  test('竖屏 9:16 走紧凑布局，图标落在可读范围内', () {
    expect(surface, closeTo(135, 0.5));
    expect(needsCompactControls(surface), isTrue);
    expect(iconSize, inInclusiveRange(12, 22));
    // 旧布局：24 + 3*34 + 40 = 166 > 135，这就是之前 RenderFlex overflowed 的来源。
    expect(24 + 3 * 34 + 40, greaterThan(surface));
  });

  testWidgets('135px 播放区里平分按钮不溢出，且三个槽一样宽', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: surface,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: VideoCompactNavBar(
                      iconSize: iconSize,
                      onPrevious: () {},
                      onNext: () {},
                      onPlaylist: () {},
                    ),
                  ),
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.fullscreen, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);

    final slots = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .toList();
    expect(slots.length, 3);
    final widths = tester
        .renderObjectList<RenderBox>(find.descendant(
          of: find.byType(VideoCompactNavBar),
          matching: find.byType(IconButton),
        ))
        .map((box) => box.size.width)
        .toList();
    expect(widths.length, 3);
    for (final w in widths) {
      expect(w, closeTo(widths.first, 0.5));
      expect(w, greaterThanOrEqualTo(iconSize));
    }
  });

  testWidgets('没有播放列表时只平分两个按钮', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 111,
            child: VideoCompactNavBar(iconSize: 16, onPrevious: () {}),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);
    expect(find.byIcon(Icons.playlist_play), findsNothing);
  });
}
