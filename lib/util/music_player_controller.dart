import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/music_library.dart';
import 'package:media_kit/media_kit.dart';
import 'package:signals/signals.dart';

/// 音乐的播放状态：列表、当前下标、一个常驻 Player。
///
/// 列表体和全屏播放页共用同一个实例，两边都自己订阅 `player.stream.*`，
/// 只有这里的队列/下标是需要共享的部分。
class MusicPlayerController {
  // 建 Player 就会碰 media_kit 原生库，所以等真正要播的时候再建
  Player? _player;
  Player get player => _player ??= Player()
    ..stream.completed.listen((done) {
      // 一首放完自动下一首，最后一首就停着
      if (done && index.value < songs.value.length - 1) next();
    });
  final songs = signal<List<MusicSong>>([]);
  final index = signal<int>(-1);

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
    await player.open(Media(_urlOf(list[i])));
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
