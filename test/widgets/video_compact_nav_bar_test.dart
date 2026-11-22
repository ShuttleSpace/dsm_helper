import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/video_compact_nav_bar.dart';
import 'package:garden/widgets/video_player_controls_layout.dart';

/// media_kit 底部条：左右外边距 16/8，里面是自定义按钮 + 全屏键。
/// 竖屏 9:16 视频在 360x800 屏上播放区只有 135px，固定宽度按钮会溢出，
/// 所以三个导航按钮用 Expanded 平分，图标跟着缩。
void main() {
  const width = 140.0;
  final iconSize = compactNavIconSize(width);

  test('竖屏容器满宽，只有窄窗口才走紧凑布局', () {
    expect(needsCompactControls(360), isFalse);
    expect(needsCompactControls(158), isFalse);
    expect(needsCompactControls(width), isTrue);
    expect(iconSize, inInclusiveRange(12, 22));
  });

  testWidgets('窄播放区里平分按钮不溢出，且三个槽一样宽', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
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

    final slots =
        tester.widgetList<IconButton>(find.byType(IconButton)).toList();
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
            width: 111.0,
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
