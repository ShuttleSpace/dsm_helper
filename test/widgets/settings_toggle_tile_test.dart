import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/settings/settings_toggle_tile.dart';

void main() {
  testWidgets('SettingsToggleTile shows a checkmark only when enabled',
      (tester) async {
    var taps = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsToggleTile(
          label: '启用SMB服务',
          value: false,
          onTap: () => taps++,
        ),
      ),
    ));

    expect(find.text('启用SMB服务'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsNothing);

    await tester.tap(find.text('启用SMB服务'));
    expect(taps, 1);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsToggleTile(
          label: '启用SMB服务',
          value: true,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget);
  });
}
