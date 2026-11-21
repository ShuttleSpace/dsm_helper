import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('obsolete folder_item_widget is gone and unreferenced', () {
    expect(File('lib/pages/photos/widgets/folder_item_widget.dart').existsSync(),
        isFalse);
    for (final path in [
      'lib/pages/photos/folder.dart',
      'lib/pages/photos/album_tab.dart',
      'lib/pages/photos/photo_tab.dart',
    ]) {
      expect(File(path).readAsStringSync(), isNot(contains('folder_item_widget')));
    }
  });
}
