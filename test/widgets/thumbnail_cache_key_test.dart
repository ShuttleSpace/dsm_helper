import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/cupertino_image.dart';

void main() {
  const base = 'http://nas:5000/webapi/entry.cgi?id=12&cache_key="abc"'
      '&type="unit"&size="sm"&api="SYNO.Foto.Thumbnail"&method="get"';

  test('_sid 不入 key：重登后仍命中同一个缓存文件', () {
    expect(
      thumbnailCacheKey('$base&_sid=AAA'),
      thumbnailCacheKey('$base&_sid=BBB'),
    );
  });

  test('cache_key / size 变化会得到不同 key（图片变了要重新下）', () {
    final sm = thumbnailCacheKey('$base&_sid=AAA');
    final xl = thumbnailCacheKey(
        '${base.replaceAll('size="sm"', 'size="xl"')}&_sid=AAA');
    final newer = thumbnailCacheKey('${base.replaceAll('abc', 'def')}&_sid=AAA');
    expect(sm, isNot(xl));
    expect(sm, isNot(newer));
  });

  test('key 是 md5，可直接当文件名', () {
    final key = thumbnailCacheKey('$base&_sid=AAA');
    expect(key, matches(RegExp(r'^[0-9a-f]{32}$')));
  });
}
