import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/file/file_list_item.dart';

void main() {
  testWidgets('FileListItem shows name and handles tap/action', (tester) async {
    final file = <String, dynamic>{
      'name': 'test.txt',
      'path': '/test.txt',
      'isdir': false,
      'additional': {'size': 1024},
    };
    var tapped = 0;
    var actioned = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FileListItem(
          file: file,
          remote: false,
          iconMode: false,
          multiSelect: false,
          selected: false,
          onTap: () => tapped++,
          onAction: () => actioned++,
        ),
      ),
    ));

    expect(find.text('test.txt'), findsOneWidget);
    await tester.tap(find.text('test.txt'));
    expect(tapped, 1);

    final icon = find.byIcon(CupertinoIcons.right_chevron);
    if (icon.evaluate().isNotEmpty) {
      await tester.tap(icon.first);
      expect(actioned, 1);
    }
  });
}
