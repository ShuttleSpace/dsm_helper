import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/backup/backup.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

void main() {
  test('collectBackupAssets flattens albums and dedupes assets by id', () async {
    // Regression: old fold([], ...) inferred List<dynamic> and
    // `uploads.addAll(values as List<AssetEntity>)` threw _CastError,
    // leaving the backup asset count at 0 and the start button dead.
    final albums = [
      AssetPathEntity(id: 'a', name: 'a'),
      AssetPathEntity(id: 'b', name: 'b'),
    ];
    final result = await collectBackupAssets(
      albums,
      fetch: (album) async => album.id == 'a'
          ? [fakeAsset('1'), fakeAsset('2')]
          : [fakeAsset('2'), fakeAsset('3')],
    );
    expect(result.map((e) => e.id), ['1', '2', '3']);
    expect(result.every((e) => e is AssetEntity), isTrue);
  });

  test('backupCacheDirName strips slashes and punctuation', () {
    expect(backupCacheDirName('91D2/L0/001'), '91D2_L0_001');
  });
}

AssetEntity fakeAsset(String id) => AssetEntity(
      id: id,
      typeInt: 1,
      width: 100,
      height: 100,
    );
