import 'dart:convert';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/nfo_util.dart';
import 'package:garden/util/storage_util.dart';

/// 库目录设置（JSON 字符串数组）。
const String mediaLibraryPathsStorageKey = 'media_library_paths';

/// 扫库的最大深度，库目录自身算第 0 层。
const int mediaScanDepth = 3;

/// 媒体库里的一条视频，封面/NFO/字幕都取自它所在目录。
class MediaItem {
  final String name;
  final String path;
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

/// 读一条的 NFO，返回带上标题/年份/评分/类型的副本；没有 NFO 或读失败原样返回。
Future<MediaItem> fillMediaNfo(MediaItem item) async {
  if (item.nfoPath.isEmpty) return item;
  try {
    final bytes = await fetchFileBytes(fbDownloadUrl(
      baseUri: connectionStore.baseUri.value,
      path: item.nfoPath,
      sid: connectionStore.sid.value,
      mode: 'open',
    ));
    final detail = parseNfoDetail(utf8.decode(bytes));
    return detail == null ? item : item.copyWithNfo(detail);
  } catch (e) {
    Log.error("读 NFO 失败 ${item.nfoPath}: $e");
    return item;
  }
}
