import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';

void main() {
  testWidgets('BottomConfirmSheet returns confirm result and calls onConfirm',
      (tester) async {
    Object? result;
    var confirmed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCupertinoModalPopup(
                context: context,
                builder: (context) => BottomConfirmSheet(
                  title: '下载确认',
                  content: '是否继续？',
                  confirmText: '下载',
                  confirmResult: true,
                  cancelResult: false,
                  onConfirm: () => confirmed = true,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下载'));
    await tester.pumpAndSettle();

    expect(result, true);
    expect(confirmed, isTrue);
  });

  testWidgets('BottomConfirmSheet cancel returns cancel result', (tester) async {
    Object? result;
    var confirmed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCupertinoModalPopup(
                context: context,
                builder: (context) => BottomConfirmSheet(
                  title: '下载确认',
                  content: '是否继续？',
                  cancelResult: false,
                  onConfirm: () => confirmed = true,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(result, false);
    expect(confirmed, isFalse);
  });
}
