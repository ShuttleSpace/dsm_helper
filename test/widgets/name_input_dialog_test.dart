import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/name_input_dialog.dart';

void main() {
  testWidgets('NameInputDialog returns the typed name via onConfirm',
      (tester) async {
    String? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCupertinoDialog(
              context: context,
              builder: (context) => NameInputDialog(
                title: '重命名',
                onConfirm: (name) async => submitted = name,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('重命名'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'new name');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(submitted, 'new name');
    expect(find.byType(NameInputDialog), findsNothing);
  });
}
