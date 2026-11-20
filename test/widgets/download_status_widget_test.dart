import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/download/download_status_widget.dart';

void main() {
  testWidgets('running shows progress bar and percentage', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DownloadStatusWidget(status: TaskStatus.running, progress: 45),
    ));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(0.45, 0.001));
    expect(find.text('45%'), findsOneWidget);
  });

  testWidgets('complete shows text without progress bar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DownloadStatusWidget(status: TaskStatus.complete, progress: 100),
    ));

    expect(find.text('下载完成'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
