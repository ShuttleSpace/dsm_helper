import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/bottom_action_sheet.dart';

void main() {
  testWidgets('BottomActionSheet renders actions and closes before callback',
      (tester) async {
    var tapped = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCupertinoModalPopup(
              context: context,
              builder: (context) => BottomActionSheet(
                title: '选择操作',
                actions: [
                  BottomActionItem(
                    label: '详情',
                    iconAsset: 'assets/icons/info_liner.png',
                    onPressed: () => tapped++,
                  ),
                  BottomActionItem(
                    label: '删除',
                    iconAsset: 'assets/icons/delete.png',
                    labelColor: Colors.redAccent,
                    onPressed: () => tapped += 10,
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('选择操作'), findsOneWidget);
    expect(find.byType(BottomActionSheet), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(tapped, 10);
    expect(find.byType(BottomActionSheet), findsNothing);
  });
}
