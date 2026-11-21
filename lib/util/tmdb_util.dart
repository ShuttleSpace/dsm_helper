import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:garden/extensions/string.dart';
import 'package:path_provider/path_provider.dart';

/// TMDB API key 存在本地的键名。免费注册：https://www.themoviedb.org/settings/api
const String tmdbApiKeyStorageKey = 'tmdb_api_key';

const String _tmdbHost = 'https://api.themoviedb.org/3';
const String _tmdbImageHost = 'https://image.tmdb.org/t/p/w500';

/// 缓存有效期与条数上限：同一部片子重复打开不必再查。
const Duration tmdbCacheTtl = Duration(days: 30);
const int tmdbCacheLimit = 200;

/// 刮削结果，字段刻意与 NFO 对齐，播放页复用同一套展示。
class TmdbInfo {
  final String title;
  final String overview;
  final String year;
  final String genres;
  final String runtime;
  final String rating;
  final String premiered;
  final String poster;

  const TmdbInfo({
    this.title = '',
    this.overview = '',
    this.year = '',
    this.genres = '',
    this.runtime = '',
    this.rating = '',
    this.premiered = '',
    this.poster = '',
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'overview': overview,
        'year': year,
        'genres': genres,
        'runtime': runtime,
        'rating': rating,
        'premiered': premiered,
        'poster': poster,
      };

  factory TmdbInfo.fromJson(Map json) => TmdbInfo(
        title: '${json['title'] ?? ''}',
        overview: '${json['overview'] ?? ''}',
        year: '${json['year'] ?? ''}',
        genres: '${json['genres'] ?? ''}',
        runtime: '${json['runtime'] ?? ''}',
        rating: '${json['rating'] ?? ''}',
        premiered: '${json['premiered'] ?? ''}',
        poster: '${json['poster'] ?? ''}',
      );
}

Future<File?> _tmdbCacheFile() async {
  try {
    final dir = await getApplicationSupportDirectory();
    return File("${dir.path}/tmdb_cache.json");
  } catch (_) {
    return null;
  }
}

/// 读缓存：同一文件名 30 天内的结果直接复用，失败当未命中。
Future<TmdbInfo?> readTmdbCache(String fileName) async {
  try {
    final file = await _tmdbCacheFile();
    if (file == null || !await file.exists()) return null;
    final all = jsonDecode(await file.readAsString());
    final entry = all is Map ? all[fileName] : null;
    if (entry is! Map) return null;
    final ts = entry['ts'];
    if (ts is! int) return null;
    final age =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age > tmdbCacheTtl) return null;
    final info = entry['info'];
    return info is Map ? TmdbInfo.fromJson(info) : null;
  } catch (_) {
    return null;
  }
}

/// 写缓存：超过上限按时间清最旧的。
Future<void> writeTmdbCache(String fileName, TmdbInfo info) async {
  try {
    final file = await _tmdbCacheFile();
    if (file == null) return;
    Map<String, dynamic> all = <String, dynamic>{};
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) all = Map<String, dynamic>.from(decoded);
    }
    all[fileName] = <String, dynamic>{
      'ts': DateTime.now().millisecondsSinceEpoch,
      'info': info.toJson(),
    };
    if (all.length > tmdbCacheLimit) {
      final keys = all.keys.toList()
        ..sort((a, b) =>
            (all[a]['ts'] as int? ?? 0).compareTo(all[b]['ts'] as int? ?? 0));
      for (final key in keys.take(all.length - tmdbCacheLimit)) {
        all.remove(key);
      }
    }
    await file.writeAsString(jsonEncode(all));
  } catch (_) {
    // 缓存写失败不影响播放
  }
}

/// 从文件名猜查询用的片名与年份：`流浪地球2.2023.1080p.BluRay.x264.mkv` → (流浪地球2, 2023)。
///
/// 规则只做两件事：去掉扩展名，从第一个 19xx/20xx 处截断并当作年份；其余分隔符换空格。
({String title, String year}) guessTitleFromFileName(String fileName) {
  var text = fileName.split('/').last;
  final dot = text.lastIndexOf('.');
  if (dot > 0) text = text.substring(0, dot);
  var year = '';
  final match = RegExp(r'(?:^|\D)((?:19|20)\d{2})(?!\d)').firstMatch(text);
  if (match != null) {
    final start = match.start + match.group(0)!.length - match.group(1)!.length;
    final before = _cleanName(text.substring(0, start));
    // `1917.mkv` 这种片名本身是年份的不截断。
    if (before.isNotBlank) {
      year = match.group(1)!;
      text = before;
    }
  }
  return (title: _cleanName(text), year: year);
}

String _cleanName(String text) => text
    .replaceAll(RegExp(r'[._\-\[\]()]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// 从 `search/multi` 结果里挑一条：优先年份匹配且有条目简介的 movie / tv。
({int id, String mediaType})? pickSearchHit(dynamic json, String year) {
  if (json is! Map) return null;
  final results = json['results'];
  if (results is! List) return null;
  ({int id, String mediaType})? fallback;
  for (final item in results) {
    if (item is! Map) continue;
    final mediaType = '${item['media_type'] ?? ''}';
    if (mediaType != 'movie' && mediaType != 'tv') continue;
    final id = item['id'];
    if (id is! int) continue;
    final date = '${item['release_date'] ?? item['first_air_date'] ?? ''}';
    final hit = (id: id, mediaType: mediaType);
    if (year.isNotBlank && date.startsWith(year)) return hit;
    fallback ??= hit;
  }
  return fallback;
}

/// 把 `/{media_type}/{id}` 的详情转成展示字段。
TmdbInfo? parseTmdbDetail(dynamic json, String mediaType) {
  if (json is! Map) return null;
  final genres = json['genres'];
  final runtime = mediaType == 'tv'
      ? (json['episode_run_time'] is List &&
              (json['episode_run_time'] as List).isNotEmpty
          ? json['episode_run_time'][0]
          : '')
      : (json['runtime'] ?? '');
  final posterPath = '${json['poster_path'] ?? ''}';
  final date = '${json['release_date'] ?? json['first_air_date'] ?? ''}';
  return TmdbInfo(
    title: '${json['title'] ?? json['name'] ?? ''}',
    overview: '${json['overview'] ?? ''}',
    year: date.length >= 4 ? date.substring(0, 4) : '',
    genres: genres is List
        ? genres
            .map((e) => e is Map ? '${e['name'] ?? ''}' : '')
            .where((e) => e.isNotBlank)
            .join('、')
        : '',
    runtime: '$runtime',
    rating: '${json['vote_average'] ?? ''}',
    premiered: date,
    poster: posterPath.startsWith('/') ? '$_tmdbImageHost$posterPath' : '',
  );
}

/// 查 TMDB：`search/multi` 找片 → 取详情。没有 key、没查到、网络失败都返回 null。
Future<TmdbInfo?> fetchTmdbInfo(String apiKey, String fileName) async {
  if (apiKey.isBlank) return null;
  final cached = await readTmdbCache(fileName);
  if (cached != null) return cached;
  final query = guessTitleFromFileName(fileName);
  if (query.title.isBlank) return null;
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  try {
    final search = await dio.get('$_tmdbHost/search/multi', queryParameters: {
      'api_key': apiKey,
      'language': 'zh-CN',
      'query': query.title,
      'include_adult': 'false',
    });
    final hit = pickSearchHit(search.data, query.year);
    if (hit == null) return null;
    final detail = await dio.get('$_tmdbHost/${hit.mediaType}/${hit.id}',
        queryParameters: {'api_key': apiKey, 'language': 'zh-CN'});
    final info = parseTmdbDetail(detail.data, hit.mediaType);
    if (info != null) await writeTmdbCache(fileName, info);
    return info;
  } catch (e) {
    return null;
  }
}
