import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/video_nav_menu.dart';
import 'package:garden/widgets/video_player_controls_layout.dart';

/// 底部控制条只有 media_kit 的左 16 / 右 8 外边距可用，宽度不够时
/// 「上一个/下一个/播放列表」必须收进一个菜单，否则竖屏视频报 RenderFlex overflowed。
void main() {
  const portraitScreen = Size(360, 800); // 9:16 视频播放区只有 135px 宽

  test('竖屏 9:16 走后一种布局，且底部菜单放得下', () {
    final surface = playerSurfaceWidth(portraitScreen, 9 / 16);
    expect(surface, closeTo(135, 0.5));
    expect(needsCompactControls(surface), isTrue);
    expect(fitsCompactBottomBar(surface), isTrue);
    expect(bottomBarMinWidth(compact: true), lessThan(surface));
    // 旧布局：三个 34px 按钮 + 全屏键 + 外边距 = 166px > 135px，所以必然溢出。
    expect(24 + 3 * 34 + 40, greaterThan(surface));
  });

  test('极窄（<104）时底部连菜单也不放，只留全屏键', () {
    expect(fitsCompactBottomBar(100), isFalse);
  });

  testWidgets('紧凑底部条在 135px 播放区里不溢出，菜单能弹出三项', (tester) async {
    final surface = playerSurfaceWidth(portraitScreen, 9 / 16);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            width: surface,
            color: Colors.black,
            // 复刻 media_kit 底部条：左右外边距 + 菜单 + 全屏键
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              children: [
                const Spacer(),
                VideoNavMenu(
                  onPrevious: () {},
                  onNext: () {},
                  onPlaylist: () {},
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('上一个'), findsOneWidget);
    expect(find.text('下一个'), findsOneWidget);
    expect(find.text('播放列表'), findsOneWidget);
  });

  testWidgets('没有上一个/下一个时菜单只剩播放列表', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VideoNavMenu(onPlaylist: () {}),
      ),
    ));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('播放列表'), findsOneWidget);
    expect(find.text('上一个'), findsNothing);
  });
}
