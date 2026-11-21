import 'dart:convert';
import 'dart:io';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/nfo_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:garden/util/storage_util.dart';

/// 库目录设置（JSON 字符串数组）。
const String mediaLibraryPathsStorageKey = 'media_library_paths';

/// 扫库的最大深度，库目录自身算第 0 层。
const int mediaScanDepth = 3;

/// 媒体库里的一条视频，封面/NFO/字幕都取自它所在目录。
class MediaItem {
  final String name;
  final String path;

  /// 同目录封面（NAS path），没有本地封面时可能被填成 TMDB 的 http URL。
  final String coverPath;
  final String nfoPath;
  final List<String> subtitles;
  final String title;
  final String year;
  final String rating;
  final String genres;

  const MediaItem({
    required this.name,
    required this.path,
    this.coverPath = '',
    this.nfoPath = '',
    this.subtitles = const [],
    this.title = '',
    this.year = '',
    this.rating = '',
    this.genres = '',
  });

  /// 显示名：NFO 标题优先，否则去扩展名的文件名。
  String get displayTitle {
    if (title.isNotBlank) return title;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// 副标题：年份 / 评分 / 类型，空的不出现。
  String get subtitleLine => [year, rating, genres]
      .where((e) => e.isNotBlank && e != 'null')
      .join(' · ');

  MediaItem withCover(String cover) => MediaItem(
        name: name,
        path: path,
        coverPath: cover,
        nfoPath: nfoPath,
        subtitles: subtitles,
        title: title,
        year: year,
        rating: rating,
        genres: genres,
      );

  MediaItem copyWithNfo(Map detail) => MediaItem(
        name: name,
        path: path,
        coverPath: coverPath,
        nfoPath: nfoPath,
        subtitles: subtitles,
        title: '${detail['title'] ?? ''}'.trim(),
        year: '${detail['year'] ?? ''}'.trim(),
        rating: '${detail['rating'] ?? ''}'.trim(),
        genres: joinNfoNames(detail['genre']),
      );
}

Future<List<String>> loadMediaLibraryPaths() async {
  final raw = await StorageUtil.getString(mediaLibraryPathsStorageKey) ?? '[]';
  try {
    final list = jsonDecode(raw);
    return list is List ? list.map((e) => '$e').toList() : <String>[];
  } catch (_) {
    return <String>[];
  }
}

Future<void> saveMediaLibraryPaths(List<String> paths) =>
    StorageUtil.setString(mediaLibraryPathsStorageKey, jsonEncode(paths));

/// 广度优先扫库目录，收集视频及其同目录的封面/NFO/字幕。
/// 单个目录失败只记日志，不影响其它目录。
Future<List<MediaItem>> scanMediaLibrary(List<String> roots) async {
  final items = <MediaItem>[];
  final queue = roots.map((e) => (e, 0)).toList();
  while (queue.isNotEmpty) {
    final (dir, depth) = queue.removeAt(0);
    final List<Map<String, dynamic>> files;
    try {
      final data = await dsmFileStationListForPage(dir);
      files = (data['files'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      Log.error("扫库目录失败 $dir: $e");
      continue;
    }
    if (depth < mediaScanDepth) {
      for (final f in files.where((e) => e['isdir'] == true)) {
        queue.add(('${f['path']}', depth + 1));
      }
    }
    for (final f in files.where((e) => e['isdir'] != true)) {
      final name = '${f['name']}';
      final dot = name.lastIndexOf('.');
      if (dot <= 0) continue;
      if (!FileTypeUtil.movieExtensions
          .contains(name.substring(dot + 1).toLowerCase())) {
        continue;
      }
      final base = name.substring(0, dot);
      items.add(MediaItem(
        name: name,
        path: '${f['path']}',
        coverPath: _pickCover(files, base),
        nfoPath: _pickNfo(files, base),
        subtitles: FileTypeUtil.findSiblingSubtitles(files, base),
      ));
    }
  }
  return items;
}

/// 封面候选按优先级找：`<片名>-fanart` → `-poster` → `-thumb` → 目录里的 fanart/poster/cover/thumb。
String _pickCover(List<Map<String, dynamic>> files, String base) {
  // 先认同名图片：一个目录里多部片时，靠这个才认得出各自的封面
  final lower = base.toLowerCase();
  for (final f in files) {
    final name = '${f['name']}'.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot > 0 &&
        name.substring(0, dot) == lower &&
        FileTypeUtil.imageExtensions.contains(name.substring(dot + 1))) {
      return '${f['path']}';
    }
  }
  final keys = [
    for (final suffix in const ['fanart', 'poster', 'thumb', 'cover'])
      '$base-$suffix'.toLowerCase(),
    'fanart',
    'poster',
    'cover',
    'thumb',
  ];
  for (final key in keys) {
    for (final f in files) {
      if ('${f['name']}'.toLowerCase().startsWith(key)) return '${f['path']}';
    }
  }
  return '';
}

String _pickNfo(List<Map<String, dynamic>> files, String base) {
  for (final f in files) {
    if ('${f['name']}'.toLowerCase() == '${base.toLowerCase()}.nfo') {
      return '${f['path']}';
    }
  }
  for (final f in files) {
    if ('${f['name']}'.toLowerCase().endsWith('.nfo')) return '${f['path']}';
  }
  return '';
}

enum MediaSort { name, year, rating }

/// 搜索 + 排序（页面和测试共用）。
List<MediaItem> filterAndSortMediaItems(
    List<MediaItem> items, String query, MediaSort sort) {
  final q = query.trim().toLowerCase();
  final list = q.isEmpty
      ? [...items]
      : items
          .where((e) =>
              e.displayTitle.toLowerCase().contains(q) ||
              e.name.toLowerCase().contains(q))
          .toList();
  int byYear(MediaItem a, MediaItem b) =>
      (int.tryParse(b.year) ?? 0).compareTo(int.tryParse(a.year) ?? 0);
  switch (sort) {
    case MediaSort.year:
      list.sort(byYear);
    case MediaSort.rating:
      list.sort((a, b) => (double.tryParse(b.rating) ?? 0)
          .compareTo(double.tryParse(a.rating) ?? 0));
    case MediaSort.name:
      list.sort((a, b) =>
          a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
  }
  return list;
}

/// NFO 缓存（键 = NFO 的 NAS path，30 天过期）。NFO 平时不改，所以不按 mtime 失效。
const Duration mediaNfoCacheTtl = Duration(days: 30);
const int mediaNfoCacheLimit = 500;

Future<File?> _nfoCacheFile() async {
  try {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/media_nfo_cache.json');
  } catch (e) {
    Log.error("NFO 缓存目录取不到: $e");
    return null;
  }
}

Future<Map<String, dynamic>> _readNfoCache() async {
  final file = await _nfoCacheFile();
  if (file == null || !await file.exists()) return {};
  try {
    final json = jsonDecode(await file.readAsString());
    return json is Map ? Map<String, dynamic>.from(json) : {};
  } catch (e) {
    Log.error("NFO 缓存损坏，忽略: $e");
    return {};
  }
}

Future<void> _writeNfoCache(Map<String, dynamic> cache) async {
  final file = await _nfoCacheFile();
  if (file == null) return;
  try {
    await file.writeAsString(jsonEncode(cache));
  } catch (e) {
    Log.error("NFO 缓存写入失败: $e");
  }
}

/// 过期和不认识的条目丢掉，超过上限按 ts 淘汰最旧（纯函数，便于测试）。
Map<String, dynamic> pruneNfoCache(Map<String, dynamic> cache,
    {DateTime? now}) {
  final ttl =
      (now ?? DateTime.now()).subtract(mediaNfoCacheTtl).millisecondsSinceEpoch;
  final valid = <String, dynamic>{};
  for (final entry in cache.entries) {
    final value = entry.value;
    final ts = value is Map ? (value['ts'] as num?)?.toInt() : null;
    if (ts != null && ts >= ttl) valid[entry.key] = value;
  }
  if (valid.length <= mediaNfoCacheLimit) return valid;
  final keys = valid.keys.toList()
    ..sort((a, b) => ((valid[a]['ts'] as num?)?.toInt() ?? 0)
        .compareTo((valid[b]['ts'] as num?)?.toInt() ?? 0));
  for (final key in keys.take(valid.length - mediaNfoCacheLimit)) {
    valid.remove(key);
  }
  return valid;
}

/// 读一条的 NFO（带本地缓存），返回带上标题/年份/评分/类型的副本。
Future<MediaItem> fillMediaNfo(MediaItem item) async {
  if (item.nfoPath.isEmpty) return item;
  final cache = await _readNfoCache();
  final cached = cache[item.nfoPath];
  if (cached is Map) {
    return item.copyWithNfo(Map<String, dynamic>.from(cached));
  }
  try {
    final bytes = await fetchFileBytes(fbDownloadUrl(
      baseUri: connectionStore.baseUri.value,
      path: item.nfoPath,
      sid: connectionStore.sid.value,
      mode: 'open',
    ));
    final detail = parseNfoDetail(utf8.decode(bytes));
    if (detail == null) return item;
    final pruned = pruneNfoCache({
      ...cache,
      item.nfoPath: {...detail, 'ts': DateTime.now().millisecondsSinceEpoch},
    });
    await _writeNfoCache(pruned);
    return item.copyWithNfo(detail);
  } catch (e) {
    Log.error("读 NFO 失败 ${item.nfoPath}: $e");
    return item;
  }
}

/// 继续观看：单键 JSON，path → {pos, dur, ts}（秒）。
const String continueWatchingStorageKey = 'continue_watching';
const int continueWatchingLimit = 30;

Future<Map<String, dynamic>> loadContinueWatching() async {
  final raw = await StorageUtil.getString(continueWatchingStorageKey) ?? '{}';
  try {
    final json = jsonDecode(raw);
    return json is Map ? Map<String, dynamic>.from(json) : {};
  } catch (_) {
    return {};
  }
}

/// 记一次播放进度；快看完（剩不到 5%）就当作看完、清掉这条。
Future<void> savePlayProgress(String path, Duration position,
    {required Duration duration}) async {
  if (path.isEmpty || duration.inSeconds <= 0) return;
  final all = await loadContinueWatching();
  if (position.inSeconds < 5 ||
      position.inSeconds > duration.inSeconds * 0.95) {
    all.remove(path);
  } else {
    all[path] = {
      'pos': position.inSeconds,
      'dur': duration.inSeconds,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
  }
  final keys = all.keys.toList()
    ..sort((a, b) => ((all[b] as Map)['ts'] as num? ?? 0)
        .compareTo((all[a] as Map)['ts'] as num? ?? 0));
  for (final key in keys.skip(continueWatchingLimit).toList()) {
    all.remove(key);
  }
  await StorageUtil.setString(continueWatchingStorageKey, jsonEncode(all));
}

/// 某条已看到的位置（用于海报上的进度条和续播），没看过返回 null。
Future<Duration?> resumePosition(String path) async {
  final all = await loadContinueWatching();
  final entry = all[path];
  final pos = entry is Map ? (entry['pos'] as num?)?.toInt() : null;
  return pos == null || pos <= 0 ? null : Duration(seconds: pos);
}
