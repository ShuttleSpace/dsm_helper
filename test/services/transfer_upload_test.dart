import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garden/api/dsm_api.filestation.transfer_contract.dart';
import 'package:garden/services/transfer_upload.dart';
import 'package:garden/stores/connection_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() {
    connectionStore.setBaseUri('http://192.168.8.40:5000/');
    connectionStore.setSynoToken('TOK');
  });

  test('splitFileIntoTempChunks splits 20MB into 3 parts (8/8/4)', () {
    final file = File('${Directory.systemTemp.path}/up_src_20m.bin');
    file.writeAsBytesSync(List.filled(20 * 1024 * 1024, 7));

    final chunks = splitFileIntoTempChunks(file, chunkSize: 8 * 1024 * 1024);
    addTearDown(() => file.deleteSync());

    expect(chunks.length, 3);
    expect(chunks[0].offset, 0);
    expect(chunks[1].offset, 8 * 1024 * 1024);
    expect(chunks[2].offset, 16 * 1024 * 1024);
    expect(chunks[0].size, 8 * 1024 * 1024);
    expect(chunks[1].size, 8 * 1024 * 1024);
    expect(chunks[2].size, 4 * 1024 * 1024);
    // 临时文件字节数与 size 一致
    for (final c in chunks) {
      final tmp = File(c.tempPath);
      addTearDown(() => tmp.deleteSync());
      expect(tmp.lengthSync(), c.size);
    }
  });

  test('splitFileIntoTempChunks returns empty for zero-length file', () {
    final file = File('${Directory.systemTemp.path}/up_empty.bin')
      ..writeAsBytesSync([]);
    addTearDown(() => file.deleteSync());
    expect(splitFileIntoTempChunks(file), isEmpty);
  });

  test('v2UploadFields assembles path/overwrite/mtime', () {
    expect(
      v2UploadFields(remotePath: '/home/a.txt', overwrite: true, mtime: 123),
      {'path': '/home/a.txt', 'overwrite': 'true', 'mtime': '123'},
    );
    expect(
      v2UploadFields(remotePath: '/home/a.txt', overwrite: false),
      {'path': '/home/a.txt', 'overwrite': 'false'},
    );
  });

  test('v3UploadFields carries part metadata and upload_id when given', () {
    const f = UploadV3Fields();
    final fields = v3UploadFields(
      remotePath: '/home/a.txt',
      filename: 'a.txt',
      partNumber: 2,
      totalParts: 3,
      offset: 8 * 1024 * 1024,
      offsetSize: 4 * 1024 * 1024,
      overwrite: true,
      mtime: 9,
      uploadId: 'UID',
    );
    expect(fields[f.partNumber], '2');
    expect(fields[f.totalParts], '3');
    expect(fields[f.offset], '${8 * 1024 * 1024}');
    expect(fields[f.offsetSize], '${4 * 1024 * 1024}');
    expect(fields[f.uploadId], 'UID');
    expect(fields[f.overwrite], 'true');
  });
}
