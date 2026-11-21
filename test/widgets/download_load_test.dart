import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/pages/download/download_state.dart';

class _FakeDownloadStateNotifier extends DownloadStateNotifier {
  bool initCalled = false;

  @override
  void init() {
    initCalled = true;
    loading.value = false;
  }
}

void main() {
  testWidgets('Download initializes notifier and leaves loading', (tester) async {
    final notifier = _FakeDownloadStateNotifier();
    await tester.pumpWidget(MaterialApp(
      home: DownloadStateInherited(notifier: notifier, child: const Download()),
    ));
    await tester.pump();

    expect(notifier.initCalled, isTrue);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    expect(find.text('全部'), findsOneWidget);
  });
}
