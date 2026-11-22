import 'dart:async';

import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/music_library.dart';
import 'package:garden/util/storage_util.dart';
import 'package:media_kit/media_kit.dart';
import 'package:signals/signals.dart';

/// 播放模式：顺序（放完列表就停）/ 列表循环 / 单曲（放完停）/ 单曲循环。
enum MusicPlayMode { sequential, loop, single, singleLoop }

const String musicPlayModeStorageKey = 'music_play_mode';

String musicPlayModeLabel(MusicPlayMode mode) => switch (mode) {
      MusicPlayMode.sequential => '顺序播放',
      MusicPlayMode.loop => '列表循环',
      MusicPlayMode.single => '单曲播放',
      MusicPlayMode.singleLoop => '单曲循环',
    };

/// 一首放完之后该转到哪个下标；null 表示停下。
int? indexAfterComplete(int index, int length, MusicPlayMode mode) {
  if (length <= 0 || index < 0 || index >= length) return null;
  return switch (mode) {
    MusicPlayMode.single => null,
    MusicPlayMode.singleLoop => index,
    MusicPlayMode.sequential => index + 1 < length ? index + 1 : null,
    MusicPlayMode.loop => (index + 1) % length,
  };
}

/// 音乐的播放状态：列表、当前下标、一个常驻 Player。
///
/// 列表体和全屏播放页共用同一个实例，两边都自己订阅 `player.stream.*`，
/// 只有这里的队列/下标是需要共享的部分。
class MusicPlayerController {
  // 建 Player 就会碰 media_kit 原生库，所以等真正要播的时候再建
  Player? _player;
  Player get player => _player ??= _createPlayer();

  // 每次访问 `.player` 都挂监听的话，completed 会被触发 N 次，歌会一路跳到最后一首
  Player _createPlayer() {
    final created = Player();
    created.stream.completed.listen((completed) {
      if (completed) _onCompleted();
    });
    created.stream.error.listen((error) => Log.error("音乐播放失败: $error"));
    return created;
  }

  final songs = signal<List<MusicSong>>([]);
  final index = signal<int>(-1);
  final playMode = signal(MusicPlayMode.sequential);
  // open 过程中会冒 completed，别让它自己连跳
  bool _opening = false;

  MusicPlayerController() {
    unawaited(_loadPlayMode());
  }

  Future<void> _loadPlayMode() async {
    final saved = await StorageUtil.getString(musicPlayModeStorageKey);
    playMode.value = MusicPlayMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => MusicPlayMode.sequential,
    );
  }

  Future<void> setPlayMode(MusicPlayMode mode) async {
    playMode.value = mode;
    await StorageUtil.setString(musicPlayModeStorageKey, mode.name);
  }

  Future<void> _onCompleted() async {
    if (_opening) return;
    final target =
        indexAfterComplete(index.value, songs.value.length, playMode.value);
    if (target == null) return;
    await play(songs.value, target);
  }

  MusicSong? get current {
    final list = songs.value;
    final i = index.value;
    return i >= 0 && i < list.length ? list[i] : null;
  }

  bool get hasPrev => index.value > 0;
  bool get hasNext => index.value < songs.value.length - 1;

  /// 播放 [list] 里的第 [i] 首。
  Future<void> play(List<MusicSong> list, int i) async {
    if (i < 0 || i >= list.length) return;
    songs.value = list;
    index.value = i;
    _opening = true;
    try {
      await player.open(Media(_urlOf(list[i])));
    } catch (e) {
      Log.error("音乐打开失败: $e");
    } finally {
      _opening = false;
    }
  }

  Future<void> next() async {
    if (!hasNext) return;
    await play(songs.value, index.value + 1);
  }

  Future<void> prev() async {
    if (!hasPrev) return;
    await play(songs.value, index.value - 1);
  }

  Future<void> toggle() => player.playOrPause();

  Future<void> seek(Duration position) => player.seek(position);

  Duration get position => player.state.position;

  Duration get duration => player.state.duration;

  String _urlOf(MusicSong song) => fbDownloadUrl(
        baseUri: connectionStore.baseUri.value,
        path: song.path,
        sid: connectionStore.sid.value,
        mode: 'open',
      );

  Future<void> dispose() async => await _player?.dispose();
}

/// 全局单例：页面和系统通知栏（audio_service）要共用同一个播放器。
final MusicPlayerController musicController = MusicPlayerController();
