import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/list_cache.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('list_cache_test');
    ListCache.rootForTest = root;
    ListCache.clear();
    connectionStore.setBaseUri('http://nas.test/');
    connectionStore.setAccount('alice');
  });

  tearDown(() {
    ListCache.rootForTest = null;
    ListCache.clear();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('内存命中后不再读磁盘', () async {
    await ListCache.write('photos|timeline', [
      {'id': 1}
    ]);
    // 删掉磁盘快照，仍能读到 → 说明来自内存。
    for (final f in root.listSync()) {
      f.deleteSync();
    }
    expect(await ListCache.read('photos|timeline'), [
      {'id': 1}
    ]);
  });

  test('磁盘快照跨启动可读（内存清空后仍命中）', () async {
    await ListCache.write('files|/photo', {'files': ['a.jpg', 'b.jpg']});
    ListCache.clear();
    expect(await ListCache.read('files|/photo'), {
      'files': ['a.jpg', 'b.jpg']
    });
  });

  test('换账号不读到上一个账号的快照', () async {
    await ListCache.write('photos|timeline', ['alice-photo']);
    ListCache.clear();
    connectionStore.setAccount('bob');
    expect(await ListCache.read('photos|timeline'), isNull);
  });

  test('不同 key 互不干扰', () async {
    await ListCache.write('photos|timeline|personal', ['personal']);
    await ListCache.write('photos|timeline|team', ['team']);
    ListCache.clear();
    expect(await ListCache.read('photos|timeline|personal'), ['personal']);
    expect(await ListCache.read('photos|timeline|team'), ['team']);
  });

  test('超过 maxAge 的磁盘快照当作未命中', () async {
    await ListCache.write('photos|timeline', ['old']);
    ListCache.clear();
    for (final f in root.listSync()) {
      final data = f as File;
      final text = data.readAsStringSync();
      data.writeAsStringSync(text.replaceFirst(
          RegExp(r'"t":\d+'),
          '"t":${DateTime.now()
              .subtract(ListCache.maxAge + const Duration(days: 1))
              .millisecondsSinceEpoch}'));
    }
    expect(await ListCache.read('photos|timeline'), isNull);
  });

  test('磁盘内容损坏时返回 null 而不是抛错', () async {
    await ListCache.write('photos|timeline', ['x']);
    ListCache.clear();
    (root.listSync().first as File).writeAsStringSync('not json');
    expect(await ListCache.read('photos|timeline'), isNull);
  });
}
