import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/settings/settings_checkbox_tile.dart';

void main() {
  testWidgets('SettingsCheckboxTile shows state and handles tap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsCheckboxTile(
          label: '震动',
          value: true,
          onTap: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('震动'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    await tester.tap(find.text('震动'));
    expect(tapped, isTrue);
  });
}
