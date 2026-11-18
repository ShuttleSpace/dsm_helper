import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/storage_manager/smart_info_item.dart';
import 'package:garden/widgets/storage_manager/smart_log_item.dart';

void main() {
  testWidgets('smart info and log items render their data', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ListView(
        children: const [
          SmartInfoItem({
            'id': '5',
            'status': 'OK',
            'name': '温度',
            'current': 30,
            'worst': 25,
            'threshold': 60,
            'raw': 100,
          }),
          SmartLogItem({
            'time': '2026-01-01',
            'result': 'smart_complete',
            'test_type': 'quick',
          }),
        ],
      ),
    ));

    expect(find.text('温度'), findsOneWidget);
    expect(find.text('S.M.A.R.T. 快速测试'), findsOneWidget);
  });
}
