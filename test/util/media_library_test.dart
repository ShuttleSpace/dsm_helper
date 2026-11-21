import 'package:garden/pages/media/play_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/storage_util.dart';

void main() {
  tearDown(() => dsmFileStationPageRequestForTesting = null);

  test('扫库目录：挑出视频并带同目录封面/NFO/字幕，子目录递归', () async {
    dsmFileStationPageRequestForTesting = (String endpoint,
        {Map<String, dynamic>? data,
        Map<String, dynamic>? queryParameters}) async {
      return switch (data?['folder_path']) {
        '/video' => {
            'success': true,
            'data': {
              'files': [
                {'name': '电影A.mkv', 'path': '/video/电影A.mkv', 'isdir': false},
                {'name': '电影A.srt', 'path': '/video/电影A.srt', 'isdir': false},
                {'name': '电影A.nfo', 'path': '/video/电影A.nfo', 'isdir': false},
                {
                  'name': 'poster.jpg',
                  'path': '/video/poster.jpg',
                  'isdir': false
                },
                {'name': '电影A.jpg', 'path': '/video/电影A.jpg', 'isdir': false},
                {'name': '说明.txt', 'path': '/video/说明.txt', 'isdir': false},
                {'name': 'S2', 'path': '/video/S2', 'isdir': true},
              ]
            }
          },
        '/video/S2' => {
            'success': true,
            'data': {
              'files': [
                {
                  'name': 'ep1.mp4',
                  'path': '/video/S2/ep1.mp4',
                  'isdir': false
                },
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
    // 同名片名图优先，不会被目录里的 poster.jpg 抢走
    expect(movie.coverPath, '/video/电影A.jpg');
    expect(movie.nfoPath, '/video/电影A.nfo');
    expect(movie.subtitles, ['/video/电影A.srt']);
    expect(movie.displayTitle, '电影A');
    expect(movie.subtitleLine, '');
  });

  test('displayTitle / subtitleLine 用 NFO 的值', () async {
    const item = MediaItem(
        name: 'a.mkv',
        path: '/a.mkv',
        title: '片名',
        year: '2024',
        rating: '8.1');
    expect(item.displayTitle, '片名');
    expect(item.subtitleLine, '2024 · 8.1');
  });

  test('搜索按片名/NFO 标题匹配，三种排序都对', () {
    const a = MediaItem(
        name: 'a.mkv',
        path: '/a.mkv',
        title: '海贼王',
        year: '2020',
        rating: '8.0');
    const b = MediaItem(
        name: 'batman.mkv',
        path: '/b.mkv',
        title: '蝙蝠侠',
        year: '2024',
        rating: '7.5');
    const c = MediaItem(name: 'c.mkv', path: '/c.mkv'); // 无边数据

    final all = [a, b, c];
    expect(filterAndSortMediaItems(all, '蝙蝠', MediaSort.name), [b]);
    expect(
        filterAndSortMediaItems(all, 'BAT', MediaSort.name), [b]); // 文件名大小写不敏感
    expect(filterAndSortMediaItems(all, '', MediaSort.year), [b, a, c]);
    expect(filterAndSortMediaItems(all, '', MediaSort.rating), [a, b, c]);
    expect(filterAndSortMediaItems(all, '', MediaSort.name).first.displayTitle,
        'c');
    expect(filterAndSortMediaItems(all, '  ', MediaSort.name).length, 3);
  });

  test('NFO 缓存裁掉过期条目并按 ts 淘汰超额', () {
    final now = DateTime(2026, 11, 21);
    final fresh = now.millisecondsSinceEpoch;
    final old = now.subtract(const Duration(days: 40)).millisecondsSinceEpoch;

    expect(
        pruneNfoCache({
          'a': {'ts': old},
          'b': {'ts': fresh}
        }, now: now)
            .keys,
        ['b']);
    // 没有 ts 的坏条目也丢掉
    expect(
        pruneNfoCache({
          'x': {'title': 'nope'}
        }, now: now),
        isEmpty);

    final big = {
      for (var i = 0; i < mediaNfoCacheLimit + 5; i++) 'n$i': {'ts': fresh + i}
    };
    final pruned = pruneNfoCache(big, now: now);
    expect(pruned.length, mediaNfoCacheLimit);
    expect(pruned.containsKey('n0'), isFalse); // 最旧的先掉
    expect(pruned.containsKey('n${mediaNfoCacheLimit + 4}'), isTrue);
  });

  test('播放进度：记住、快看完清掉、超量淘汰', () async {
    SharedPreferences.setMockInitialValues({});
    await savePlayProgress('/a.mkv', const Duration(minutes: 10),
        duration: const Duration(minutes: 100));
    expect(await resumePosition('/a.mkv'), const Duration(minutes: 10));

    await savePlayProgress('/a.mkv', const Duration(minutes: 99),
        duration: const Duration(minutes: 100));
    expect(await resumePosition('/a.mkv'), isNull);

    await savePlayProgress('/b.mkv', const Duration(seconds: 2),
        duration: const Duration(minutes: 100));
    expect(await resumePosition('/b.mkv'), isNull);

    for (var i = 0; i < continueWatchingLimit + 3; i++) {
      await savePlayProgress('/c$i.mkv', const Duration(minutes: 5),
          duration: const Duration(minutes: 100));
    }
    expect((await loadContinueWatching()).length, continueWatchingLimit);
  });

  test('多媒体设置：深度默认 3 层、TMDB 补封面默认开，改完能读回', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await loadMediaScanDepth(), 3);
    expect(await loadMediaUseTmdbPoster(), true);

    await StorageUtil.setInt(mediaScanDepthStorageKey, 5);
    await StorageUtil.setBool(mediaUseTmdbPosterStorageKey, false);
    expect(await loadMediaScanDepth(), 5);
    expect(await loadMediaUseTmdbPoster(), false);
  });

  test('按文件夹分组：目录做键，组内保持传入顺序', () async {
    const items = [
      MediaItem(name: 'b.mkv', path: '/video/电影/b.mkv'),
      MediaItem(name: 'a.mkv', path: '/video/a.mkv'),
      MediaItem(name: 'c.mkv', path: '/tv/剧/c.mkv'),
      MediaItem(name: 'd.mkv', path: '/video/电影/d.mkv'),
    ];
    final groups = groupByFolder(items);
    expect(groups.keys.toList(), ['/video/电影', '/video', '/tv/剧']);
    expect(groups['/video/电影']!.map((e) => e.name), ['b.mkv', 'd.mkv']);
    expect(await loadMediaViewMode(), MediaViewMode.poster);
    await saveMediaViewMode(MediaViewMode.folder);
    expect(await loadMediaViewMode(), MediaViewMode.folder);
  });

  test('文件树：按路径折出目录，同名目录合并，总数含子目录', () {
    const items = [
      MediaItem(name: 'a.mkv', path: '/video/电影/a.mkv'),
      MediaItem(name: 'b.mkv', path: '/video/电影/2024/b.mkv'),
      MediaItem(name: 'c.mkv', path: '/video/电影/c.mkv'),
      MediaItem(name: 'd.mkv', path: '/tv/d.mkv'),
    ];
    final root = buildMediaTree(items);
    expect(root.folders.map((e) => e.name), ['video', 'tv']);
    final video = root.folders.first;
    expect(video.total, 3);
    final movie = video.folders.first;
    expect(movie.path, '/video/电影');
    expect(movie.videos.map((e) => e.name), ['a.mkv', 'c.mkv']);
    expect(movie.folders.single.path, '/video/电影/2024');
    expect(root.folders.last.videos.single.name, 'd.mkv');
  });

  test('播放历史：坏数据丢掉、按时间倒序、进度和看完判定', () {
    final records = parsePlayHistory({
      '/a.mkv': {'pos': 100, 'dur': 200, 'ts': 1000},
      '/b.mkv': {'pos': 995, 'dur': 1000, 'ts': 3000},
      '/bad.mkv': {'pos': 'x'},
      '/c.mkv': 'not a map',
    });
    expect(records.map((e) => e.path), ['/b.mkv', '/a.mkv']);
    expect(records.first.name, 'b');
    expect(records.first.finished, isTrue);
    expect(records.last.progress, 0.5);
    expect(records.last.remaining, const Duration(seconds: 100));
    expect(parsePlayHistory(null), isEmpty);
  });

  test('时长文案：秒 / 分钟 / 小时', () {
    expect(formatPlayDuration(const Duration(seconds: 30)), '30 秒');
    expect(formatPlayDuration(const Duration(minutes: 45)), '45 分钟');
    expect(formatPlayDuration(const Duration(hours: 2)), '2 小时');
    expect(
        formatPlayDuration(const Duration(hours: 1, minutes: 5)), '1 小时 5 分钟');
  });
}
