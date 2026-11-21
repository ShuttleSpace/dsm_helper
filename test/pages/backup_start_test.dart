import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/backup/backup.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('backupPendingAssets filters by modifiedDateTime for continue', () {
    final older = FakeAsset('1', DateTime(2026, 1, 1));
    final newer = FakeAsset('2', DateTime(2026, 2, 1));
    final since = DateTime(2026, 1, 15);
    expect(backupPendingAssets([older, newer], since, true), [newer]);
    expect(backupPendingAssets([older, newer], since, false).length, 2);
  });

  test('startBackup adds one parent with one step per asset and keeps modifyTime',
      () async {
    final cacheRoot = await Directory.systemTemp.createTemp('backup_test_');
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    final source = File('${cacheRoot.path}/source.jpg')
      ..writeAsStringSync('photo');
    final asset = FakeAsset('91D2/L0/001', DateTime(2026, 2, 1),
        sourceFile: source);
    final parent = await startBackup(
      backupFolder: '/photos',
      assets: [asset],
      cacheRoot: cacheRoot,
      enqueue: (cachePath, remoteDir) async => 'step1',
    );
    expect(parent.steps!.length, 1);
    expect(parent.steps!.first.id, 'step1');
    expect(parent.steps!.first.modifyTime, asset.modifiedDateTime);
    expect(parent.steps!.first.localPath, contains('91D2_L0_001'));
    expect(transferStore.tasks.value.any((t) => t.id == parent.id), isTrue);
    transferStore.remove(parent.id);
  });

  test('partial enqueue failure stays failed after earlier step completes',
      () async {
    final cacheRoot = await Directory.systemTemp.createTemp('backup_test_');
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    final first = File('${cacheRoot.path}/first.jpg')
      ..writeAsStringSync('photo');
    final second = File('${cacheRoot.path}/second.jpg')
      ..writeAsStringSync('photo');
    final assets = [
      FakeAsset('a', DateTime(2026, 2, 1), sourceFile: first),
      FakeAsset('b', DateTime(2026, 2, 2), sourceFile: second),
    ];
    final canceled = <String>[];
    await expectLater(
      () => startBackup(
        backupFolder: '/photos',
        assets: assets,
        cacheRoot: cacheRoot,
        enqueue: (cachePath, remoteDir) async {
          if (cachePath.endsWith('/first.jpg')) return 'step1';
          throw Exception('offline');
        },
        cancelEnqueued: (id) async => canceled.add(id),
      ),
      throwsA(isA<BackupEnqueueIncomplete>()),
    );
    final parent = transferStore.tasks.value.firstWhere((t) => t.id.startsWith('backup_'));
    expect(parent.state, TransferState.error);
    expect(parent.errorMessage, contains('offline'));
    expect(canceled, ['step1']);

    transferStore.applyTaskStatus('step1', TaskStatus.complete);
    final after = transferStore.tasks.value.firstWhere((t) => t.id == parent.id);
    expect(after.state, TransferState.error);
    expect(after.errorMessage, contains('offline'));
    transferStore.remove(parent.id);
  });

test('hasPendingBackupTask true only for stepped queued/active tasks', () {
  final queued = TransferTask(
    id: 'b1',
    type: TransferType.upload,
    localPath: '',
    remotePath: '/p',
    state: TransferState.queued,
    steps: const [],
  );
  final plain = TransferTask(
    id: 'u1',
    type: TransferType.upload,
    localPath: '/a.jpg',
    remotePath: '/p/a.jpg',
    state: TransferState.active,
  );
  final done = queued.copyWith(state: TransferState.done);
  final paused = queued.copyWith(state: TransferState.paused);
  expect(hasPendingBackupTask([queued]), isTrue);
  expect(hasPendingBackupTask([plain]), isFalse);
  expect(hasPendingBackupTask([done]), isFalse);
  expect(hasPendingBackupTask([paused]), isTrue);
});

test('startAutoBackup skips when disabled, no folder, pending task or nothing new',
    () async {
  final cacheRoot = await Directory.systemTemp.createTemp('auto_backup_test_');
  addTearDown(() => cacheRoot.deleteSync(recursive: true));
  final source = File('${cacheRoot.path}/new.jpg')..writeAsStringSync('photo');
  final asset = FakeAsset('new', DateTime(2026, 2, 1), sourceFile: source);
  final enqueue = (String cachePath, String remoteDir) async => 'auto1';

  expect(
      await startAutoBackup(
          enabled: false,
          backupFolder: '/photos',
          uploads: [asset],
          lastBackupTime: null,
          hasPendingBackup: false,
          enqueue: enqueue,
          cacheRoot: cacheRoot),
      isNull);
  expect(
      await startAutoBackup(
          enabled: true,
          backupFolder: '',
          uploads: [asset],
          lastBackupTime: null,
          hasPendingBackup: false,
          enqueue: enqueue,
          cacheRoot: cacheRoot),
      isNull);
  expect(
      await startAutoBackup(
          enabled: true,
          backupFolder: '/photos',
          uploads: [asset],
          lastBackupTime: null,
          hasPendingBackup: true,
          enqueue: enqueue,
          cacheRoot: cacheRoot),
      isNull);
  expect(
      await startAutoBackup(
          enabled: true,
          backupFolder: '/photos',
          uploads: [asset],
          lastBackupTime: DateTime(2026, 3, 1),
          hasPendingBackup: false,
          enqueue: enqueue,
          cacheRoot: cacheRoot),
      isNull);
  expect(transferStore.tasks.value.any((t) => t.id.startsWith('backup_')), isFalse);
});

test('startAutoBackup creates parent task when eligible', () async {
  final cacheRoot = await Directory.systemTemp.createTemp('auto_backup_test_');
  addTearDown(() => cacheRoot.deleteSync(recursive: true));
  final source = File('${cacheRoot.path}/new.jpg')..writeAsStringSync('photo');
  final asset = FakeAsset('new', DateTime(2026, 2, 1), sourceFile: source);
  final parent = await startAutoBackup(
    enabled: true,
    backupFolder: '/photos',
    uploads: [asset],
    lastBackupTime: DateTime(2026, 1, 1),
    hasPendingBackup: false,
    enqueue: (cachePath, remoteDir) async => 'auto1',
    cacheRoot: cacheRoot,
  );
  expect(parent!.steps!.single.id, 'auto1');
  expect(parent.remotePath, '/photos');
  transferStore.remove(parent.id);
});

test('startAutoBackup cancels already-enqueued steps when a later one fails',
    () async {
  final cacheRoot = await Directory.systemTemp.createTemp('auto_backup_test_');
  addTearDown(() => cacheRoot.deleteSync(recursive: true));
  final first = File('${cacheRoot.path}/first.jpg')..writeAsStringSync('photo');
  final second = File('${cacheRoot.path}/second.jpg')
    ..writeAsStringSync('photo');
  final canceled = <String>[];
  await expectLater(
    () => startAutoBackup(
      enabled: true,
      backupFolder: '/photos',
      uploads: [
        FakeAsset('a', DateTime(2026, 1, 1), sourceFile: first),
        FakeAsset('b', DateTime(2026, 1, 2), sourceFile: second),
      ],
      lastBackupTime: null,
      hasPendingBackup: false,
      cacheRoot: cacheRoot,
      enqueue: (cachePath, remoteDir) async {
        if (cachePath.endsWith('/first.jpg')) return 'auto1';
        throw Exception('offline');
      },
      cancelEnqueued: (id) async => canceled.add(id),
    ),
    throwsA(isA<BackupEnqueueIncomplete>()),
  );
  expect(canceled, ['auto1']);
  for (final t in transferStore.tasks.value.where((t) => t.steps != null)) {
    transferStore.remove(t.id);
  }
});

test('runAutoBackup does nothing when the switch is off', () async {
  SharedPreferences.setMockInitialValues({'auto_backup': false});
  expect(await runAutoBackup(), isNull);
  expect(transferStore.tasks.value.where((t) => t.steps != null), isEmpty);
});
}

class FakeAsset extends AssetEntity {
  FakeAsset(String id, this.when, {this.sourceFile})
      : super(id: id, typeInt: 1, width: 100, height: 100);

  final DateTime when;
  final File? sourceFile;

  @override
  DateTime get modifiedDateTime => when;

  @override
  Future<File?> get originFile async => sourceFile;
}
