import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/media/media_setting.dart';
import 'package:garden/util/storage_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('多媒体设置：保存 TMDB Key、切开关、读扫描深度', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'media_scan_depth': 5, 'media_use_tmdb_poster': true});

    await tester.pumpWidget(const OKToast(
      child: MaterialApp(home: MediaSetting()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('媒体库目录'), findsOneWidget);
    expect(find.text('5 层'), findsOneWidget);
    expect(find.text('5 层'), findsWidgets);

    // 关掉 TMDB 补封面
    await tester.tap(find.text('没封面时用 TMDB 海报'));
    await tester.pumpAndSettle();
    expect(await StorageUtil.getBool('media_use_tmdb_poster'), isFalse);

    await tester.enterText(find.byType(TextField), '  abc123  ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(await StorageUtil.getString('tmdb_api_key'), 'abc123');
    // 排掉 oktoast 的定时器，否则测试以 pending timer 失败
    await tester.pump(const Duration(seconds: 3));
  });
}
