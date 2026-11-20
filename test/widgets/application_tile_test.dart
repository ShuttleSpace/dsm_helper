import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/application_tile.dart';

void main() {
  testWidgets('ApplicationTile renders label and handles tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ApplicationTile(
          iconAsset: 'assets/applications/docker.png',
          label: 'Docker',
          onTap: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('Docker'), findsOneWidget);
    await tester.tap(find.text('Docker'));
    expect(tapped, isTrue);
  });
}
