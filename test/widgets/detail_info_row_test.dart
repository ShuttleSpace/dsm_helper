import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/download_station/detail_info_row.dart';

void main() {
  testWidgets('DetailInfoRow renders label and value', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DetailInfoRow.text(label: '文件名：', text: 'test.zip'),
      ),
    ));

    expect(find.text('文件名：'), findsOneWidget);
    expect(find.text('test.zip'), findsOneWidget);
  });
}
