import 'dart:convert';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/storage_util.dart';

/// 音乐目录单独一组设置（和视频库目录互不影响）。
const String musicLibraryPathsStorageKey = 'music_library_paths';

Future<List<String>> loadMusicLibraryPaths() async {
  final raw = await StorageUtil.getString(musicLibraryPathsStorageKey);
  if (raw == null || raw.isEmpty) return [];
  try {
    final list = jsonDecode(raw);
    if (list is List) return [for (final e in list) '$e'];
  } catch (e) {
    Log.info("音乐目录配置坏了: $e");
  }
  return [];
}

Future<void> saveMusicLibraryPaths(List<String> paths) async {
  await StorageUtil.setString(musicLibraryPathsStorageKey, jsonEncode(paths));
}

/// 一首歌：标签来自 Audio Station 的索引，封面按 `id` 现取。
class MusicSong {
  final String id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final int seconds;

  const MusicSong({
    required this.id,
    required this.path,
    required this.title,
    this.artist = '',
    this.album = '',
    this.seconds = 0,
  });

  /// 副行：艺人 · 专辑，空的不出现。
  String get subtitleLine =>
      [artist, album].where((e) => e.isNotBlank && e != 'null').join(' · ');

  Duration get duration => Duration(seconds: seconds);
}

/// 歌名 / 艺人 / 专辑。
enum MusicSort { title, artist, album }

List<MusicSong> sortMusicSongs(List<MusicSong> songs, MusicSort sort) {
  final indexed = [...songs.asMap().entries];
  indexed.sort((a, b) {
    final x = a.value;
    final y = b.value;
    final c = switch (sort) {
      MusicSort.title => x.title.compareTo(y.title),
      MusicSort.artist => x.artist.compareTo(y.artist),
      MusicSort.album => x.album.compareTo(y.album),
    };
    return c != 0 ? c : a.key.compareTo(b.key);
  });
  return [for (final e in indexed) e.value];
}

/// 把 Audio Station 的返回摊平成歌曲列表。
///
/// [dirs] 为空表示整个音乐库；非空时只留这些目录下的歌。Audio Station 返回的
/// `path` 对共享库是 NAS 上的真实路径，所以直接和目录配置比前缀。
///
/// shortcut: 靠前缀比对，个人库/虚拟库的 path 可能不是真实路径，那时会筛空，
/// 等真机上拿到实际 path 再按需映射。
List<MusicSong> parseMusicSongs(dynamic data, List<String> dirs) {
  final songs = data is Map ? data['songs'] : null;
  if (songs is! List) return [];
  final result = <MusicSong>[];
  for (final raw in songs) {
    if (raw is! Map) continue;
    final path = '${raw['path'] ?? ''}';
    if (path.isEmpty) continue;
    if (dirs.isNotEmpty && !dirs.any((dir) => path.startsWith(dir))) continue;
    final tag = raw['additional']?['song_tag'] is Map
        ? raw['additional']['song_tag'] as Map
        : const {};
    final audio = raw['additional']?['song_audio'] is Map
        ? raw['additional']['song_audio'] as Map
        : const {};
    // 没标签时用文件名，去掉扩展名
    final fileName = path.split('/').last;
    final dot = fileName.lastIndexOf('.');
    final title = '${raw['title'] ?? ''}';
    result.add(MusicSong(
      id: '${raw['id'] ?? path}',
      path: path,
      title: title.isBlank || title == 'null'
          ? (dot > 0 ? fileName.substring(0, dot) : fileName)
          : title,
      artist: '${tag['artist'] ?? raw['artist'] ?? ''}',
      album: '${tag['album'] ?? raw['album'] ?? ''}',
      seconds:
          int.tryParse('${audio['duration'] ?? raw['duration'] ?? ''}') ?? 0,
    ));
  }
  return result;
}

/// 拉整库（或指定目录下的）歌。没有 Audio Station 会抛 DSMException。
Future<List<MusicSong>> loadMusicLibrary({List<String> dirs = const []}) async {
  Map data;
  try {
    data = await dsmAudioStationSongList();
  } catch (e) {
    // 有些 DSM 只认 personal，all 会报 1022
    Log.info("Audio Station(all) 取歌失败，改试 personal: $e");
    data = await dsmAudioStationSongList(library: 'personal');
  }
  return parseMusicSongs(data, dirs);
}

/// 歌曲封面直链（Audio Station 按歌曲 id 给图）。
String musicCoverUrl(MusicSong song) => audioCoverUrl(
      baseUri: connectionStore.baseUri.value,
      id: song.id,
      sid: connectionStore.sid.value,
    );

/// 时长文案：`3:07` / `1:02:05`。
String formatSongDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
      : '$minutes:${seconds.toString().padLeft(2, '0')}';
}
