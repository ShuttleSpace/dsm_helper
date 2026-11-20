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
