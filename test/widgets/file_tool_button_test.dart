import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/file/tool_button.dart';

void main() {
  testWidgets('FileToolButton applies side padding and handles tap',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FileToolButton(
          alignLeft: true,
          onTap: () => tapped = true,
          child: const Icon(Icons.close),
        ),
      ),
    ));

    final padding = tester.widget<Padding>(find.byType(Padding).first);
    expect(padding.padding, const EdgeInsets.only(left: 10, top: 8, bottom: 8));

    await tester.tap(find.byType(OutlinedButton));
    expect(tapped, isTrue);
  });
}
