import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/widgets/neu_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDownloadStateNotifier extends DownloadStateNotifier {
  @override
  void init() => loading.value = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('search in app bar; long press selects; menu folds actions',
      (tester) async {
    final notifier = _FakeDownloadStateNotifier();
    final task = TransferTask(
      id: 'toolbar-task',
      type: TransferType.upload,
      localPath: '/local/a.txt',
      remotePath: '/remote/a.txt',
      state: TransferState.done,
    );
    transferStore.add(task);
    addTearDown(() => transferStore.remove(task.id));

    await tester.pumpWidget(MaterialApp(
      home: DownloadStateInherited(notifier: notifier, child: const Download()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('传输'), findsNothing);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.checklist), findsNothing);
    expect(find.byIcon(Icons.swap_vert), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('排序'), findsOneWidget);
    expect(find.text('取消分组'), findsOneWidget);
    expect(find.text('下载设置'), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    expect(find.text('完成项'), findsOneWidget);
    expect(find.text('剩余项'), findsOneWidget);
    await tester.tap(find.text('全部').last);
    await tester.pumpAndSettle();
    expect(find.text('清空全部'), findsOneWidget);
    expect(find.text('返回'), findsOneWidget);
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(NeuCard).first);
    await tester.pumpAndSettle();
    expect(find.text('已选 1 项'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消任务'));
    await tester.pumpAndSettle();

    expect(find.text('取消任务'), findsWidgets);
    expect(find.text('返回'), findsOneWidget);
  });
}
