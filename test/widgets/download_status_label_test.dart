import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/download_station/status_label.dart';

void main() {
  testWidgets('DownloadStatusLabel maps status codes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            DownloadStatusLabel(status: 5),
            DownloadStatusLabel(status: 101),
            DownloadStatusLabel(status: 2, speedDownload: 1024),
          ],
        ),
      ),
    ));

    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('错误'), findsOneWidget);
    expect(find.textContaining('/s'), findsOneWidget);
  });
}
