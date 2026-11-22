import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/music_library.dart';

final Map<String, Uint8List?> _cache = {};

/// 抓歌曲文件里的内嵌封面。
///
/// Audio Station 的 `cover.cgi` 在部分 DSM 上一直回 101（参数怎么调都不行），
/// 而 `FileStation.Download` 支持 Range，所以直接拉文件头自己找图。
Future<Uint8List?> loadEmbeddedCover(MusicSong song) async {
  final path = song.path;
  if (_cache.containsKey(path)) return _cache[path];
  _cache[path] = null; // 占位，避免同一帧里重复发请求
  var cover = await _readCache(path);
  if (cover == null) {
    cover = await _fetchCover(fbDownloadUrl(
      baseUri: connectionStore.baseUri.value,
      path: path,
      sid: connectionStore.sid.value,
      mode: 'open',
    ));
    if (cover != null) await _writeCache(path, cover);
  }
  _cache[path] = cover;
  return cover;
}

/// 封面缓存在应用支持目录，跨会话复用，省掉重复拉 1MB 文件头。
Future<Uint8List?> _readCache(String path) async {
  try {
    final file = await _cacheFile(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<void> _writeCache(String path, Uint8List cover) async {
  try {
    await (await _cacheFile(path)).writeAsBytes(cover, flush: false);
  } catch (_) {
    // 缓存写不进去不影响显示
  }
}

Future<File> _cacheFile(String path) async {
  final dir =
      Directory('${(await getApplicationSupportDirectory()).path}/cover_cache');
  await dir.create(recursive: true);
  return File('${dir.path}/${_fnv1a(path)}.img');
}

String _fnv1a(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}

Future<Uint8List?> _fetchCover(String url) async {
  try {
    // shortcut: 只扫前 1MB，标签区比这更大（超大封面）就取不到
    final res = await Dio().get<List<int>>(
      url,
      options: Options(
        headers: {'Range': 'bytes=0-1048575'},
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    return extractCoverImage(Uint8List.fromList(res.data ?? const []));
  } catch (_) {
    return null;
  }
}

/// 在前缀里切出第一张图（ID3 的 APIC、FLAC 的 PICTURE、MP4 的 covr 都只是塞了张图）。
Uint8List? extractCoverImage(Uint8List bytes) {
  final jpeg = _indexOf(bytes, const [0xFF, 0xD8, 0xFF]);
  final png = _indexOf(bytes, const [0x89, 0x50, 0x4E, 0x47]);
  if (jpeg < 0 && png < 0) return null;
  final usePng = png >= 0 && (jpeg < 0 || png < jpeg);
  if (usePng) {
    const end = [0x49, 0x45, 0x4E, 0x44]; // IEND
    final stop = _indexOf(bytes, end, from: png);
    return stop < 0 ? null : bytes.sublist(png, stop + 8);
  }
  const end = [0xFF, 0xD9];
  final stop = _indexOf(bytes, end, from: jpeg + 3);
  return stop < 0 ? null : bytes.sublist(jpeg, stop + 2);
}

int _indexOf(Uint8List bytes, List<int> pattern, {int from = 0}) {
  outer:
  for (var i = from; i <= bytes.length - pattern.length; i++) {
    for (var j = 0; j < pattern.length; j++) {
      if (bytes[i + j] != pattern[j]) continue outer;
    }
    return i;
  }
  return -1;
}
