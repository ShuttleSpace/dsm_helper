import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('album selection compares by id', () {
    final source = File('lib/pages/common/select_ablum.dart').readAsStringSync();
    expect(source, contains('a.id == b.id'));
    expect(source, isNot(contains('selectedAlbums.value.contains(album)')));
  });

  test('backup page no longer holds legacy uploading state', () {
    final source = File('lib/pages/backup/backup.dart').readAsStringSync();
    expect(source, isNot(contains('useSignal<UploadItem?>(null)')));
    expect(source, isNot(contains('dsmFileStationUploadForPage')));
  });
}
