import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/settings/settings_action_card.dart';

void main() {
  testWidgets('SettingsActionCard renders label and trailing widget',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsActionCard(
          label: '关机',
          trailing: OutlinedButton(
            onPressed: () {},
            child: const Text('关机'),
          ),
        ),
      ),
    ));

    expect(find.text('关机'), findsNWidgets(2));
  });
}
