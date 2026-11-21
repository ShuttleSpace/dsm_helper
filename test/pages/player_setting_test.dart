import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/setting/player_setting.dart';
import 'package:garden/util/storage_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('播放器设置：切换第三方播放器、保存 TMDB Key', (tester) async {
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

    await tester.enterText(find.byType(TextField), '  abc123  ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(await StorageUtil.getString('tmdb_api_key'), 'abc123');
    // 排掉 oktoast 的定时器，否则测试以 pending timer 失败
    await tester.pump(const Duration(seconds: 3));
  });
}
