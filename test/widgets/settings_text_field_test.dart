import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/settings/settings_text_field.dart';

void main() {
  testWidgets('SettingsTextField renders label and reports changes',
      (tester) async {
    final controller = TextEditingController();
    String? changed;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsTextField(
          controller: controller,
          label: '名称',
          onChanged: (value) => changed = value,
        ),
      ),
    ));

    expect(find.text('名称'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello');
    expect(changed, 'hello');
    expect(controller.text, 'hello');
  });
}
