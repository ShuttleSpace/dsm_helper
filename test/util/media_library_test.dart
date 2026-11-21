import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/media_library.dart';

void main() {
  tearDown(() => dsmFileStationPageRequestForTesting = null);

  test('扫库目录：挑出视频并带同目录封面/NFO/字幕，子目录递归', () async {
    dsmFileStationPageRequestForTesting = (String endpoint,
        {Map<String, dynamic>? data, Map<String, dynamic>? queryParameters}) async {
      return switch (data?['folder_path']) {
        '/video' => {
            'success': true,
            'data': {
              'files': [
                {'name': '电影A.mkv', 'path': '/video/电影A.mkv', 'isdir': false},
                {'name': '电影A.srt', 'path': '/video/电影A.srt', 'isdir': false},
                {'name': '电影A.nfo', 'path': '/video/电影A.nfo', 'isdir': false},
                {'name': 'poster.jpg', 'path': '/video/poster.jpg', 'isdir': false},
                {'name': '说明.txt', 'path': '/video/说明.txt', 'isdir': false},
                {'name': 'S2', 'path': '/video/S2', 'isdir': true},
              ]
            }
          },
        '/video/S2' => {
            'success': true,
            'data': {
              'files': [
                {'name': 'ep1.mp4', 'path': '/video/S2/ep1.mp4', 'isdir': false},
              ]
            }
          },
        _ => {
            'success': false,
            'error': {'code': 900},
          },
      };
    };

    final items = await scanMediaLibrary(['/video']);

    expect(items.map((e) => e.name), ['电影A.mkv', 'ep1.mp4']);
    final movie = items.first;
    expect(movie.coverPath, '/video/poster.jpg');
    expect(movie.nfoPath, '/video/电影A.nfo');
    expect(movie.subtitles, ['/video/电影A.srt']);
    expect(movie.displayTitle, '电影A');
    expect(movie.subtitleLine, '');
  });

  test('displayTitle / subtitleLine 用 NFO 的值', () async {
    const item = MediaItem(
        name: 'a.mkv', path: '/a.mkv', title: '片名', year: '2024', rating: '8.1');
    expect(item.displayTitle, '片名');
    expect(item.subtitleLine, '2024 · 8.1');
  });
}
