import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/dashborad/applications.dart';
import 'package:garden/widgets/application_tile.dart';
import 'package:signals_flutter/signals_flutter.dart';

void main() {
  testWidgets('ApplicationList toggles between grid and list layouts',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ApplicationList(
          signal<List>([
            'SYNO.SDS.Docker.Application',
            'SYNO.SDS.XLPan.Application',
          ]),
          signal<Map>({}),
          signal<List>([]),
          signal<List>([]),
          signal<Map>({}),
        ),
      ),
    ));

    // Default: grid, with both apps wrapped in 88px boxes.
    expect(find.byTooltip('点击切换布局'), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.spacing, 12);
    expect(wrap.runSpacing, 12);
    expect(find.byType(ApplicationTile), findsNWidgets(2));
    expect(
        find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.width == 88),
        findsNWidgets(2));

    // First tap: list, with both apps in full-width rows.
    await tester.tap(find.byTooltip('点击切换布局'));
    await tester.pump();

    expect(find.byType(Wrap), findsNothing);
    expect(find.byIcon(Icons.view_list_outlined), findsOneWidget);
    expect(find.byType(Row), findsWidgets);
    expect(find.byType(ApplicationTile), findsNWidgets(2));
    expect(
        tester
            .widgetList<ApplicationTile>(find.byType(ApplicationTile))
            .every((tile) => tile.listLayout),
        isTrue);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SizedBox && widget.width == double.infinity),
        findsNWidgets(2));

    // Second tap: back to grid, with both apps still present.
    await tester.tap(find.byTooltip('点击切换布局'));
    await tester.pump();

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    expect(find.byType(ApplicationTile), findsNWidgets(2));
    expect(
        find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.width == 88),
        findsNWidgets(2));
  });
}
