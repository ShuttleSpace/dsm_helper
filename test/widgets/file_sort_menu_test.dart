import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/file/sort_menu.dart';
import 'package:signals_hooks/signals_hooks.dart';

void main() {
  testWidgets('FileSortMenu selects sort field and direction', (tester) async {
    final sortBy = Signal<String>('name');
    final direction = Signal<String>('ASC');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FileSortMenu(sortBy: sortBy, sortDirection: direction),
        ),
      ),
    ));

    expect(find.text('名称'), findsOneWidget);
    expect(find.text('修改日期'), findsOneWidget);

    await tester.tap(find.text('修改日期'));
    await tester.tap(find.text('由大至小'));
    await tester.pumpAndSettle();

    expect(sortBy.value, 'mtime');
    expect(direction.value, 'DESC');
  });
}
