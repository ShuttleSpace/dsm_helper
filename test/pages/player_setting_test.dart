import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/setting/player_setting.dart';
import 'package:garden/util/storage_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('播放器设置：切换第三方播放器、读字幕字号', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'use_embeed_video_player': false, 'subtitle_font_size': 20});

    await tester.pumpWidget(const OKToast(
      child: MaterialApp(home: PlayerSettingPage()),
    ));
    await tester.pumpAndSettle();

    // 初始值从本地读出来
    expect(find.text('优先使用第三方播放器'), findsOneWidget);
    expect(find.text('字幕字号'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);

    await tester.tap(find.text('优先使用第三方播放器'));
    await tester.pumpAndSettle();
    expect(await StorageUtil.getBool('use_embeed_video_player'), isTrue);

    // TMDB Key 挪到多媒体设置了，这里不该再有输入框
    expect(find.byType(TextField), findsNothing);
  });
}
