import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/bottom_sheet_card.dart';

void main() {
  testWidgets('BottomSheetCard wraps content in a full-width card',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BottomSheetCard(
          child: Text('内容'),
        ),
      ),
    ));

    expect(find.text('内容'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
