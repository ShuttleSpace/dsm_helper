import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/widgets/neu_card.dart';
import 'package:garden/widgets/transfer_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 传输列表的三个用户症状回归：
/// 完成项进度为 0%、样式硬编码与主题不匹配、多任务 overflow。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final source = File(
    '${Directory.current.path}/lib/widgets/transfer_list.dart',
  ).readAsStringSync();

  test('card actions live in tap sheet, not inline buttons', () {
    expect(source, contains('_showActions(context, t)'));
    expect(source, contains('BottomOptionSheet('));
    expect(source, isNot(contains('_buildControls')));
  });

  test('destructive confirm has a distinct back action', () {
    expect(source, contains("cancelText: '返回'"));
    expect(source, isNot(contains("cancelText: '取消'")));
  });

  test('cards and text use theme colors instead of hardcoded colors', () {
    expect(source, contains('NeuCard('));
    expect(source, isNot(contains('side: const BorderSide()')));
    expect(source, contains('AppTheme.of(context).titleColor'));
    expect(source, contains('AppColors.infoOf(context)'));
    expect(source, contains('AppColors.successOf(context)'));
  });

  testWidgets('done task hides progress; upload hides download-only stats', (tester) async {
    const task = TransferTask(
      id: 'done-no-bytes',
      type: TransferType.upload,
      localPath: '/local/a.txt',
      remotePath: '/remote/a.txt',
      state: TransferState.done,
    );
    transferStore.add(task);
    addTearDown(() => transferStore.remove(task.id));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TransferList(type: TransferType.upload, state: TransferState.done),
      ),
    ));

    expect(find.textContaining('100%'), findsNothing);
    expect(find.textContaining('速度'), findsNothing);
  });

  testWidgets('tap opens action sheet instead of inline remove', (tester) async {
    const task = TransferTask(
      id: 'long-press',
      type: TransferType.upload,
      localPath: '/local/a.txt',
      remotePath: '/remote/a.txt',
      state: TransferState.done,
    );
    transferStore.add(task);
    addTearDown(() => transferStore.remove(task.id));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TransferList(type: TransferType.upload, state: TransferState.done),
      ),
    ));

    expect(find.text('移除'), findsNothing);
    await tester.tap(find.byType(NeuCard).first);
    await tester.pumpAndSettle();
    expect(find.text('任务操作'), findsOneWidget);
    expect(find.text('移除'), findsWidgets);
  });

  testWidgets('long press enters multi-select when handler is provided', (tester) async {
    final task = TransferTask(
      id: 'long-select',
      type: TransferType.upload,
      localPath: '/local/a.txt',
      remotePath: '/remote/a.txt',
      state: TransferState.done,
    );
    transferStore.add(task);
    addTearDown(() => transferStore.remove(task.id));
    final selected = <String>[];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TransferList(
          type: TransferType.upload,
          state: TransferState.done,
          onLongPress: selected.add,
        ),
      ),
    ));

    await tester.longPress(find.byType(NeuCard).first);
    expect(selected, [task.id]);
    expect(find.text('任务操作'), findsNothing);
  });

  testWidgets('download shows progress; upload hides it', (tester) async {
    final download = TransferTask(
      id: 'progress-download',
      type: TransferType.download,
      localPath: '/local/a.txt',
      remotePath: '/remote/a.txt',
      transferredBytes: 1024,
      totalBytes: 2048,
      state: TransferState.active,
    );
    final upload = TransferTask(
      id: 'progress-upload',
      type: TransferType.upload,
      localPath: '/local/b.txt',
      remotePath: '/remote/b.txt',
      transferredBytes: 1024,
      totalBytes: 2048,
      state: TransferState.active,
    );
    transferStore.add(download);
    transferStore.add(upload);
    addTearDown(() {
      transferStore.remove(download.id);
      transferStore.remove(upload.id);
    });

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TransferList()),
    ));

    expect(find.textContaining('速度'), findsOneWidget);
    expect(find.textContaining('1.00K / 2.00K'), findsOneWidget);
  });

  testWidgets('many finished tasks scroll instead of overflowing', (tester) async {
    final tasks = List.generate(
      20,
      (i) => TransferTask(
        id: 'done-$i',
        type: TransferType.upload,
        localPath: '/local/$i.txt',
        remotePath: '/remote/$i.txt',
        state: TransferState.done,
      ),
    );
    for (final task in tasks) {
      transferStore.add(task);
    }
    addTearDown(() {
      for (final task in tasks) {
        transferStore.remove(task.id);
      }
    });

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: TransferList(
              type: TransferType.upload, state: TransferState.done),
        ),
      ),
    ));

    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
