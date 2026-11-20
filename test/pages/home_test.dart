import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/home.dart';
import 'package:oktoast/oktoast.dart';

void main() {
  testWidgets('Home builds and switches tabs via signal', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const OKToast(
          child: MaterialApp(home: Home()),
        ),
      );
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigation is driven by the navIndex signal inside Home.
      await tester.tap(find.text('文件'));
      await tester.pump();
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await tester.tap(find.text('设置'));
      await tester.pump();
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Let the initial fire-and-forget data fetches (and their timers) settle.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}