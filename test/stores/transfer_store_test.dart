import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('TransferTask serialization', () {
    test('roundtrip preserves fields and chunks', () {
      const task = TransferTask(
        id: 't1',
        type: TransferType.download,
        localPath: '/tmp/a.zip',
        remotePath: '/Download/a.zip',
        totalBytes: 100,
        transferredBytes: 40,
        state: TransferState.active,
        chunks: [
          ChunkState(index: 0, transferred: 40, total: 100, state: TransferState.active),
        ],
      );
      final json = task.toJson();
      final restored = TransferTask.fromJson(json);
      expect(restored.toJson(), json);
    });

    test('fromJson tolerates missing optional fields', () {
      final t = TransferTask.fromJson({
        'id': 'x',
        'type': 1,
        'localPath': '/l',
        'remotePath': '/r',
        'state': 4,
      });
      expect(t.totalBytes, 0);
      expect(t.chunks, isNull);
      expect(t.type, TransferType.upload);
      expect(t.state, TransferState.error);
    });
  });

  group('state transitions', () {
    test('setState moves through queued -> active -> done', () {
      final store = TransferStore();
      store.add(const TransferTask(
        id: 't1',
        type: TransferType.download,
        localPath: '/tmp/a',
        remotePath: '/a',
      ));
      expect(store.tasks.value.first.state, TransferState.queued);

      store.setState('t1', TransferState.active);
      expect(store.tasks.value.first.state, TransferState.active);

      store.setState('t1', TransferState.done);
      expect(store.tasks.value.first.state, TransferState.done);
    });

    test('updateProgress writes transferred/total', () {
      final store = TransferStore();
      store.add(const TransferTask(
        id: 't2',
        type: TransferType.upload,
        localPath: '/l',
        remotePath: '/r',
      ));
      store.updateProgress('t2', 50, 200);
      final t = store.tasks.value.first;
      expect(t.transferredBytes, 50);
      expect(t.totalBytes, 200);
    });
  });

  group('resumeUnfinishedOnStartup', () {
    test('resumes queued/active/paused but not done/canceled', () async {
      final done = const TransferTask(
        id: 'done', type: TransferType.download,
        localPath: '/l', remotePath: '/r', state: TransferState.done,
      );
      final active = const TransferTask(
        id: 'active', type: TransferType.download,
        localPath: '/l', remotePath: '/r', state: TransferState.active,
      );
      final paused = const TransferTask(
        id: 'paused', type: TransferType.upload,
        localPath: '/l', remotePath: '/r', state: TransferState.paused,
      );
      final canceled = const TransferTask(
        id: 'canceled', type: TransferType.download,
        localPath: '/l', remotePath: '/r', state: TransferState.canceled,
      );
      final json = jsonEncode(
        [done, active, paused, canceled].map((t) => t.toJson()).toList(),
      );
      SharedPreferences.setMockInitialValues({'transfer_tasks': json});

      final resumed = <String>[];
      final store = TransferStore(
        onResume: (id) async {
          resumed.add(id);
          return true;
        },
      );
      await store.resumeUnfinishedOnStartup();

      expect(resumed, containsAll(['active', 'paused']));
      expect(resumed, isNot(contains('done')));
      expect(resumed, isNot(contains('canceled')));
      // 本地状态被翻转为 active
      final byId = {
        for (final t in store.tasks.value) t.id: t.state,
      };
      expect(byId['active'], TransferState.active);
      expect(byId['paused'], TransferState.active);
      expect(byId['done'], TransferState.done);
    });
  });
}
