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

/// 扫库深度的设置键（用户可调 1..5）。
const String mediaScanDepthStorageKey = 'media_scan_depth';

Future<int> loadMediaScanDepth() async =>
    await StorageUtil.getInt(mediaScanDepthStorageKey) ?? mediaScanDepth;

/// 本地没有封面时用 TMDB 海报补上，默认开。
const String mediaUseTmdbPosterStorageKey = 'media_use_tmdb_poster';

Future<bool> loadMediaUseTmdbPoster() async =>
    await StorageUtil.getBool(mediaUseTmdbPosterStorageKey) ?? true;

/// 海报墙的展示风格：平铺海报 / 按目录分段 / 文件树。
enum MediaViewMode { poster, folder, tree }

const String mediaViewModeStorageKey = 'media_view_mode';

Future<MediaViewMode> loadMediaViewMode() async {
  final raw = await StorageUtil.getString(mediaViewModeStorageKey);
  return MediaViewMode.values
      .firstWhere((e) => e.name == raw, orElse: () => MediaViewMode.poster);
}

Future<void> saveMediaViewMode(MediaViewMode mode) =>
    StorageUtil.setString(mediaViewModeStorageKey, mode.name);

/// 折成目录树用的一层目录。
class MediaFolder {
  final String name;
  final String path;
  final List<MediaFolder> folders = [];
  final List<MediaItem> videos = [];

  MediaFolder(this.name, this.path);

  /// 这一支下面一共多少部片（含子目录）。
  int get total =>
      videos.length + folders.fold(0, (sum, folder) => sum + folder.total);
}

/// 把平铺的片子按 NAS 路径折成目录树，根节点的名字是空的。
MediaFolder buildMediaTree(List<MediaItem> items) {
  final root = MediaFolder('', '/');
  for (final item in items) {
    final parts = item.path.split('/').where((e) => e.isNotEmpty).toList();
    var node = root;
    for (var i = 0; i < parts.length - 1; i++) {
      final path = '/${parts.take(i + 1).join('/')}';
      final matches = node.folders.where((e) => e.path == path);
      if (matches.isNotEmpty) {
        node = matches.first;
      } else {
        final folder = MediaFolder(parts[i], path);
        node.folders.add(folder);
        node = folder;
      }
    }
    node.videos.add(item);
  }
  return root;
}

/// 播放列表的排序方式。
enum PlaylistSort { name, date, size, natural }

/// 数字按数值比、其它按字符比，这样 `第2集` 不会排到 `第10集` 后面。
int naturalCompare(String a, String b) {
  final reg = RegExp(r'\d+|\D+');
  final x = reg.allMatches(a).map((e) => e[0]!).toList();
  final y = reg.allMatches(b).map((e) => e[0]!).toList();
  for (var i = 0; i < x.length && i < y.length; i++) {
    final nx = int.tryParse(x[i]);
    final ny = int.tryParse(y[i]);
    final c =
        nx != null && ny != null ? nx.compareTo(ny) : x[i].compareTo(y[i]);
    if (c != 0) return c;
  }
  return x.length.compareTo(y.length);
}

/// 播放列表排序：文件名 / 日期 / 大小按升序，自然排序只作用于文件名。
List<MediaItem> sortPlaylist(List<MediaItem> items, PlaylistSort sort) {
  final indexed = [...items.asMap().entries];
  indexed.sort((a, b) {
    final x = a.value;
    final y = b.value;
    final c = switch (sort) {
      PlaylistSort.name => x.displayTitle.compareTo(y.displayTitle),
      PlaylistSort.date => x.mtime.compareTo(y.mtime),
      PlaylistSort.size => x.size.compareTo(y.size),
      PlaylistSort.natural => naturalCompare(x.displayTitle, y.displayTitle),
    };
    return c != 0 ? c : a.key.compareTo(b.key);
  });
  return [for (final e in indexed) e.value];
}

/// 按所在目录分组，组的顺序跟传入顺序一致（已经过排序/搜索过滤）。
Map<String, List<MediaItem>> groupByFolder(List<MediaItem> items) {
  final groups = <String, List<MediaItem>>{};
  for (final item in items) {
    final slash = item.path.lastIndexOf('/');
    final dir = slash > 0 ? item.path.substring(0, slash) : '/';
    (groups[dir] ??= []).add(item);
  }
  return groups;
}

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

  /// 文件大小（字节）与修改时间（秒），没取到时是 0，播放列表按这两个排序用。
  final int size;
  final int mtime;

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
    this.size = 0,
    this.mtime = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'coverPath': coverPath,
        'nfoPath': nfoPath,
        'subtitles': subtitles,
        'title': title,
        'year': year,
        'rating': rating,
        'genres': genres,
        'size': size,
        'mtime': mtime,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        name: '${json['name'] ?? ''}',
        path: '${json['path'] ?? ''}',
        coverPath: '${json['coverPath'] ?? ''}',
        nfoPath: '${json['nfoPath'] ?? ''}',
        subtitles: [
          for (final e in (json['subtitles'] as List? ?? const [])) '$e'
        ],
        title: '${json['title'] ?? ''}',
        year: '${json['year'] ?? ''}',
        rating: '${json['rating'] ?? ''}',
        genres: '${json['genres'] ?? ''}',
        size: (json['size'] as num?)?.toInt() ?? 0,
        mtime: (json['mtime'] as num?)?.toInt() ?? 0,
      );

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
        size: size,
        mtime: mtime,
        coverPath: cover,
        nfoPath: nfoPath,
        subtitles: subtitles,
        title: title,
        year: year,
        rating: rating,
        genres: genres,
      );

  MediaItem copyWithNfo(Map detail) => MediaItem(
        size: size,
        mtime: mtime,
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
Future<List<MediaItem>> scanMediaLibrary(List<String> roots,
    {int maxDepth = mediaScanDepth}) async {
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
    if (depth < maxDepth) {
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
      final additional = f['additional'] is Map ? f['additional'] as Map : {};
      final time = additional['time'] is Map ? additional['time'] as Map : {};
      items.add(MediaItem(
        name: name,
        path: '${f['path']}',
        size: int.tryParse('${additional['size'] ?? ''}') ?? 0,
        mtime: int.tryParse('${time['mtime'] ?? ''}') ?? 0,
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

/// 清空 NFO 缓存，返回清掉的条数。
Future<int> clearNfoCache() async {
  final file = await _nfoCacheFile();
  if (file == null) return 0;
  final cache = await _readNfoCache();
  await _writeNfoCache({});
  return cache.length;
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
  // 播完的片子会从续播列表里删掉，但历史要留着（统计用）
  if (position.inSeconds >= 5) {
    await _appendPlayHistory(path, {
      'pos': position.inSeconds,
      'dur': duration.inSeconds,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

const String playHistoryStorageKey = 'play_history';
const int playHistoryLimit = 200;

/// 一条播放记录。
class PlayRecord {
  final String path;
  final int pos;
  final int dur;
  final int ts;

  const PlayRecord(
      {required this.path,
      required this.pos,
      required this.dur,
      required this.ts});

  /// 没存片名，用文件名顶上。
  String get name {
    final base = path.split('/').last;
    final dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(0, dot) : base;
  }

  double get progress => dur <= 0 ? 0 : (pos / dur).clamp(0.0, 1.0);
  bool get finished => progress >= 0.95;
  Duration get duration => Duration(seconds: dur);
  Duration get remaining => Duration(seconds: (dur - pos).clamp(0, dur));
  DateTime get watchedAt => DateTime.fromMillisecondsSinceEpoch(ts);
}

/// 历史是 path → {pos,dur,ts}；坏数据丢掉，按时间倒序。
List<PlayRecord> parsePlayHistory(dynamic raw) {
  if (raw is! Map) return const [];
  final records = <PlayRecord>[];
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    // 存的是 JSON，类型不对就当坏数据丢掉
    final pos = value['pos'] is num ? (value['pos'] as num).toInt() : null;
    final dur = value['dur'] is num ? (value['dur'] as num).toInt() : null;
    final ts = value['ts'] is num ? (value['ts'] as num).toInt() : null;
    if (pos == null || dur == null || ts == null || dur <= 0) continue;
    records.add(PlayRecord(path: '${entry.key}', pos: pos, dur: dur, ts: ts));
  }
  records.sort((a, b) => b.ts.compareTo(a.ts));
  return records;
}

Future<List<PlayRecord>> loadPlayHistory() async {
  try {
    return parsePlayHistory(
        jsonDecode(await StorageUtil.getString(playHistoryStorageKey) ?? '{}'));
  } catch (e) {
    Log.error("播放历史解析异常: $e");
    return const [];
  }
}

Future<void> _appendPlayHistory(String path, Map<String, dynamic> entry) async {
  try {
    final raw =
        jsonDecode(await StorageUtil.getString(playHistoryStorageKey) ?? '{}');
    final all = raw is Map ? Map<String, dynamic>.from(raw) : {};
    all[path] = entry;
    for (final record in parsePlayHistory(all).skip(playHistoryLimit)) {
      all.remove(record.path);
    }
    await StorageUtil.setString(playHistoryStorageKey, jsonEncode(all));
  } catch (e) {
    Log.error("播放历史写入异常: $e");
  }
}

Future<void> removePlayHistory(String path) async {
  final all = await loadPlayHistory();
  final keep = {
    for (final e in all)
      if (e.path != path) e.path: e
  };
  await StorageUtil.setString(
      playHistoryStorageKey,
      jsonEncode({
        for (final e in keep.values)
          e.path: {'pos': e.pos, 'dur': e.dur, 'ts': e.ts}
      }));
}

Future<void> clearPlayHistory() =>
    StorageUtil.setString(playHistoryStorageKey, '{}');

/// 某条已看到的位置（用于海报上的进度条和续播），没看过返回 null。
Future<Duration?> resumePosition(String path) async {
  final all = await loadContinueWatching();
  final entry = all[path];
  final pos = entry is Map ? (entry['pos'] as num?)?.toInt() : null;
  return pos == null || pos <= 0 ? null : Duration(seconds: pos);
}
