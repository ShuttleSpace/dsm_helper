import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
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

  group('applyTaskStatus (UI isolate funnel)', () {
    test('complete clears an active download so the badge count drops', () {
      final store = TransferStore();
      store.add(const TransferTask(
        id: 't1',
        type: TransferType.download,
        localPath: '/tmp/a',
        remotePath: '/a',
        state: TransferState.active,
      ));
      int inProgress() => store.tasks.value
          .where((t) =>
              t.type == TransferType.download &&
              (t.state == TransferState.active ||
                  t.state == TransferState.queued))
          .length;
      expect(inProgress(), 1);

      store.applyTaskStatus('t1', TaskStatus.complete);
      expect(store.tasks.value.first.state, TransferState.done);
      expect(inProgress(), 0);
    });

    test('running/failed/notFound map to active/error', () {
      final store = TransferStore();
      store.add(const TransferTask(
        id: 't2',
        type: TransferType.download,
        localPath: '/tmp/b',
        remotePath: '/b',
      ));
      store.applyTaskStatus('t2', TaskStatus.running);
      expect(store.tasks.value.first.state, TransferState.active);
      store.applyTaskStatus('t2', TaskStatus.failed);
      expect(store.tasks.value.first.state, TransferState.error);
    });
  });

  group('resumeUnfinishedOnStartup', () {
    test('resumes queued/active/paused but not done/canceled', () async {
      const done = TransferTask(
        id: 'done', type: TransferType.download,
        localPath: '/l', remotePath: '/r', state: TransferState.done,
      );
      const active = TransferTask(
        id: 'active', type: TransferType.download,
        localPath: '/l', remotePath: '/r', state: TransferState.active,
      );
      const paused = TransferTask(
        id: 'paused', type: TransferType.upload,
        localPath: '/l', remotePath: '/r', state: TransferState.paused,
      );
      const canceled = TransferTask(
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
