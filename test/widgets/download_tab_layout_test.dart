import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDownloadStateNotifier extends DownloadStateNotifier {
  @override
  void init() => loading.value = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('tab count badge fits narrow screens', (tester) async {
    final tasks = List.generate(
      12,
      (i) => TransferTask(
        id: 'tab-layout-task-$i',
        type: TransferType.download,
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

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: DownloadStateInherited(
          notifier: _FakeDownloadStateNotifier(), child: const Download()),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
