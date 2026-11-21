import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/bottom_option_sheet.dart';

void main() {
  testWidgets('BottomOptionSheet shows options and returns selection',
      (tester) async {
    String? selected;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCupertinoModalPopup(
              context: context,
              builder: (context) => BottomOptionSheet(
                title: '选择位置',
                options: [
                  BottomOption(
                    title: '存储空间 1',
                    subtitle: '可用 10GB',
                    onPressed: () => selected = '存储空间 1',
                  ),
                  BottomOption(
                    title: '存储空间 2',
                    onPressed: () => selected = '存储空间 2',
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

    expect(find.text('选择位置'), findsOneWidget);
    expect(find.text('可用 10GB'), findsOneWidget);

    await tester.tap(find.text('存储空间 2'));
    await tester.pumpAndSettle();

    expect(selected, '存储空间 2');
    expect(find.byType(BottomOptionSheet), findsNothing);
  });
}
