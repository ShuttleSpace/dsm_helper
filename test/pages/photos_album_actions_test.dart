import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/photos/album_tab.dart';

void main() {
  test('validateAlbumName rejects blank and overlong names', () {
    expect(validateAlbumName(null), isNotNull);
    expect(validateAlbumName('   '), isNotNull);
    expect(validateAlbumName('x' * 61), isNotNull);
    expect(validateAlbumName('  新相册  '), isNull);
  });

  test('album write UI is wired only for personal space', () {
    final src = File('lib/pages/photos/album_tab.dart').readAsStringSync();
    expect(src, contains('dsmFotoBrowseAlbumCreate('));
    expect(src, contains('dsmFotoBrowseAlbumDelete(e.id.toString())'));
    expect(src, contains('BottomActionSheet('));
    expect(src, contains('BottomConfirmSheet('));
    expect(src, contains('if (!isTeam)'));
    expect(src, contains('validateAlbumName('));
    expect(src, contains('getAlbum();'));
  });
}
