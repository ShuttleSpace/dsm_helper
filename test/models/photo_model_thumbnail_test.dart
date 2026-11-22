import 'package:flutter_test/flutter_test.dart';
import 'package:garden/models/photos/photo_model.dart';
import 'package:garden/stores/connection_store.dart';

void main() {
  setUp(() {
    connectionStore.setBaseUri('http://192.168.8.40:5000');
    connectionStore.setAccount('test');
    connectionStore.setSid('sid123');
  });

  PhotoModel video({Map<String, dynamic>? thumbnail}) => PhotoModel.fromJson({
        'id': 684388,
        'filename': 'clip.mkv',
        'type': 'video',
        'additional': {'thumbnail': thumbnail},
      });

  test('video thumbUrl falls back to item id when thumbnail unit id is missing',
      () {
    final url = Uri.parse(video(thumbnail: {
      'cache_key': null,
      'unit_id': null,
    }).thumbUrl());
    expect(url.queryParameters['id'], '684388');
    expect(url.queryParameters['cache_key'], isNull);
    expect(url.queryParameters['api'], '"SYNO.Foto.Thumbnail"');
  });

  test('video thumbUrl without an additional block also avoids a null id', () {
    final url = Uri.parse(video().thumbUrl());
    expect(url.queryParameters['id'], '684388');
    expect(url.queryParameters['cache_key'], isNull);
  });

  test('normal photo thumbUrl still uses the thumbnail unit id and cache key',
      () {
    final url = Uri.parse(video(thumbnail: {
      'cache_key': '684388_1666619080',
      'unit_id': 123,
    }).thumbUrl());
    expect(url.queryParameters['id'], '123');
    expect(url.queryParameters['cache_key'], '"684388_1666619080"');
  });
}
