import 'package:audio_service/audio_service.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/music_player_controller.dart';
import 'package:just_audio/just_audio.dart';

/// 把 [MusicPlayerController] 暴露给系统：通知栏 / 锁屏 / 耳机按键。
///
/// audio_service 还会拉起 Android 前台服务，media_kit 因此能在后台继续出声。
class MusicAudioHandler extends BaseAudioHandler {
  final MusicPlayerController controller;

  MusicAudioHandler(this.controller) {
    final player = controller.player;
    player.playingStream.listen((_) => _push());
    player.processingStateStream.listen((_) => _push());
    player.durationStream.listen((_) => _push());
    // 进度每秒推一次，通知栏的进度条才会走
    player.positionStream.listen((position) {
      if (position.inSeconds != _lastSecond) {
        _lastSecond = position.inSeconds;
        _push();
      }
    });
    controller.index.subscribe((_) => _push());
    _push();
  }

  int _lastSecond = -1;

  void _push() {
    final player = controller.player;
    final song = controller.current;
    if (song != null) {
      mediaItem.add(MediaItem(
        id: song.path,
        title: song.title,
        artist: song.artist.isBlank ? null : song.artist,
        album: song.album.isBlank ? null : song.album,
        duration: song.duration,
      ));
    }
    final processingState = switch (player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: player.playing,
      updatePosition: player.position,
    ));
  }

  @override
  Future<void> play() => controller.player.play();

  @override
  Future<void> pause() => controller.player.pause();

  @override
  Future<void> seek(Duration position) => controller.player.seek(position);

  @override
  Future<void> skipToNext() => controller.next();

  @override
  Future<void> skipToPrevious() => controller.prev();

  @override
  Future<void> stop() async {
    await controller.player.stop();
    await super.stop();
  }
}
