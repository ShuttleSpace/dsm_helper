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

  testWidgets('grid mode uses a 36px icon', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ApplicationTile(
          iconAsset: 'assets/applications/docker.png',
          label: 'Docker',
          onTap: () {},
        ),
      ),
    ));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 36);
    expect(image.height, 36);
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('listLayout puts icon before label and keeps badge',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: ApplicationTile(
            iconAsset: 'assets/applications/docker.png',
            label: 'Virtual Machine Manager',
            onTap: () {},
            listLayout: true,
            badge: const Text('!'),
          ),
        ),
      ),
    ));

    final row = tester.widget<Row>(find.byType(Row));
    expect(row.children.first, isA<Image>());
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 36);
    expect(image.height, 36);
    expect(find.text('Virtual Machine Manager'), findsOneWidget);
    expect(find.text('!'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
