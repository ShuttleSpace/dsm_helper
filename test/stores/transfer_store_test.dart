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

    test('parent with steps roundtrips JSON and legacy task has null steps', () {
      final parent = TransferTask(
        id: 'backup_1',
        type: TransferType.upload,
        localPath: '',
        remotePath: '/photos',
        state: TransferState.active,
        steps: [
          TransferStep(
            id: 'step1',
            localPath: '/cache/a.jpg',
            remotePath: '/photos/a.jpg',
            totalBytes: 100,
            transferredBytes: 40,
            state: TransferState.active,
            modifyTime: DateTime(2026, 1, 2, 3, 4, 5),
          ),
        ],
      );
      expect(TransferTask.fromJson(parent.toJson()).toJson(), parent.toJson());
      final legacy = TransferTask.fromJson({
        'id': 'old',
        'type': 1,
        'localPath': '/l',
        'remotePath': '/r',
        'state': 0,
      });
      expect(legacy.steps, isNull);
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

    test('updateProgress writes transferred/total and speed/eta', () {
      final store = TransferStore();
      store.add(const TransferTask(
        id: 't2',
        type: TransferType.upload,
        localPath: '/l',
        remotePath: '/r',
      ));
      store.updateProgress(
        't2',
        50,
        200,
        speedBytesPerSecond: 1024 * 1024,
        etaSeconds: 12,
      );
      final t = store.tasks.value.first;
      expect(t.transferredBytes, 50);
      expect(t.totalBytes, 200);
      expect(t.speedBytesPerSecond, 1024 * 1024);
      expect(t.etaSeconds, 12);
      expect(t.updatedAt, isNotNull);
    });

    test('setError and resume clear readable error', () async {
      final store = TransferStore(
        onResume: (id) async => true,
      );
      store.add(const TransferTask(
        id: 't3',
        type: TransferType.download,
        localPath: '/l',
        remotePath: '/r',
      ));
      store.setError('t3', '连接中断', statusCode: 503);
      final failed = store.tasks.value.first;
      expect(failed.state, TransferState.error);
      expect(failed.errorMessage, '连接中断');
      expect(failed.statusCode, 503);

      await store.resumeTask('t3');
      final resumed = store.tasks.value.first;
      expect(resumed.state, TransferState.active);
      expect(resumed.errorMessage, isNull);
      expect(resumed.statusCode, isNull);
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

  group('step callback routing', () {
    TransferStep stepOf(TransferTask t, String id) =>
        t.steps!.firstWhere((s) => s.id == id);

    TransferStore seededStore() {
      final store = TransferStore();
      store.add(const TransferTask(
        id: 'backup_1',
        type: TransferType.upload,
        localPath: '',
        remotePath: '/photos',
        state: TransferState.queued,
        steps: [
          TransferStep(
            id: 's1',
            localPath: '/c/a',
            remotePath: '/photos/a',
            totalBytes: 100,
            state: TransferState.queued,
          ),
          TransferStep(
            id: 's2',
            localPath: '/c/b',
            remotePath: '/photos/b',
            totalBytes: 200,
            state: TransferState.queued,
          ),
        ],
      ));
      return store;
    }

    test('engine callbacks routed by step id aggregate to parent', () {
      final store = seededStore();
      store.updateProgress('s1', 50, 100,
          speedBytesPerSecond: 1.5, etaSeconds: 7);
      var parent = store.tasks.value.first;
      expect(stepOf(parent, 's1').transferredBytes, 50);
      expect(parent.transferredBytes, 50);
      expect(parent.totalBytes, 300);
      expect(parent.state, TransferState.active);
      expect(parent.speedBytesPerSecond, 1.5);

      store.applyTaskStatus('s2', TaskStatus.complete);
      parent = store.tasks.value.first;
      expect(stepOf(parent, 's2').state, TransferState.done);

      store.updateProgress('s2', 200, 200);
      store.applyTaskStatus('s1', TaskStatus.complete);
      parent = store.tasks.value.first;
      expect(parent.state, TransferState.done);
      expect(parent.transferredBytes, 300);
    });

    test('setError on step id marks step and parent error', () {
      final store = seededStore();
      store.setError('s2', '上传失败', statusCode: 503);
      final parent = store.tasks.value.first;
      expect(stepOf(parent, 's2').state, TransferState.error);
      expect(stepOf(parent, 's2').errorMessage, '上传失败');
      expect(stepOf(parent, 's1').state, TransferState.queued);
      expect(parent.state, TransferState.error);
      expect(parent.errorMessage, '上传失败');
    });
  });

  group('engine controls', () {
    const parent = TransferTask(
      id: 'backup_1',
      type: TransferType.upload,
      localPath: '',
      remotePath: '/photos',
      state: TransferState.active,
      steps: [
        TransferStep(
          id: 's1',
          localPath: '/c/a',
          remotePath: '/photos/a',
          totalBytes: 1,
          state: TransferState.active,
        ),
        TransferStep(
          id: 's2',
          localPath: '/c/b',
          remotePath: '/photos/b',
          totalBytes: 1,
          state: TransferState.active,
        ),
      ],
    );

    test('control hooks receive step ids, not only the parent id', () async {
      final resumed = <String>[];
      final paused = <String>[];
      final canceled = <String>[];
      final store = TransferStore(
        onResume: (id) async {
          resumed.add(id);
          return true;
        },
        onPause: (id) async {
          paused.add(id);
          return true;
        },
        onCancel: (id) async {
          canceled.add(id);
          return true;
        },
      );
      store.add(parent);

      await store.resumeTask('backup_1');
      expect(resumed, ['s1', 's2']);
      await store.pauseTask('backup_1');
      expect(paused, ['s1', 's2']);
      expect(store.tasks.value.first.state, TransferState.paused);
      await store.cancelTask('backup_1');
      expect(canceled, ['s1', 's2']);
      expect(store.tasks.value.first.state, TransferState.canceled);
    });

    test('default engine controls exist when no hooks are injected', () {
      final store = TransferStore();
      expect(store.hasDefaultControlHooks, isTrue);
      expect(store.defaultControlFor('s1'), isNotNull);
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
