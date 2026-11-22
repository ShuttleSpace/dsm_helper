import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/music_library.dart';
import 'package:garden/widgets/embedded_cover.dart';
import 'package:garden/util/music_player_controller.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 全屏播放页：大封面 + 进度 + 上一个/播放暂停/下一个 + 播放列表。
/// 播放状态在 [MusicPlayerController] 里，退出这一页歌继续放。
class MusicPlayerPage extends HookWidget {
  final MusicPlayerController controller;
  const MusicPlayerPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Watch((context) {
      final song = controller.current;
      if (song == null) {
        return Scaffold(appBar: AppBar(leading: AppBackButton(context)));
      }
      return Scaffold(
        appBar: AppBar(
          leading: AppBackButton(context),
          title: Text(song.album.isBlank ? '正在播放' : song.album),
          actions: [
            IconButton(
              tooltip: '播放列表',
              icon: const Icon(Icons.queue_music),
              onPressed: () => showPlaylist(context, controller),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _cover(song),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(song.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      song.subtitleLine.isBlank ? '未知艺人' : song.subtitleLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ProgressBar(controller: controller),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: '上一首',
                    iconSize: 34,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: controller.hasPrev ? controller.prev : null,
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<bool>(
                    stream: controller.player.stream.playing,
                    initialData: controller.player.state.playing,
                    builder: (context, snapshot) => IconButton(
                      tooltip: snapshot.data == true ? '暂停' : '播放',
                      iconSize: 64,
                      icon: Icon(snapshot.data == true
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill),
                      onPressed: controller.toggle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    tooltip: '下一首',
                    iconSize: 34,
                    icon: const Icon(Icons.skip_next),
                    onPressed: controller.hasNext ? controller.next : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Widget _cover(MusicSong song) =>
      EmbeddedCover(song: song, size: 240, radius: 12);

  void showPlaylist(BuildContext context, MusicPlayerController controller) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: controller.songs.value.length,
          itemBuilder: (context, i) {
            final item = controller.songs.value[i];
            final current = i == controller.index.value;
            return ListTile(
              dense: true,
              selected: current,
              leading: Icon(current ? Icons.volume_up : Icons.music_note),
              title: Text(item.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: item.subtitleLine.isBlank
                  ? null
                  : Text(item.subtitleLine,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (!current) controller.play(controller.songs.value, i);
              },
            );
          },
        ),
      ),
    );
  }
}

/// 进度条 + 两边的时间，滑的时候就地 seek，不跟播放位置打架。
class _ProgressBar extends HookWidget {
  final MusicPlayerController controller;
  const _ProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final dragging = useRef<double?>(null);
    return StreamBuilder<Duration>(
      stream: controller.player.stream.position,
      initialData: controller.player.state.position,
      builder: (context, posSnapshot) {
        final duration = controller.player.state.duration;
        final total = duration.inMilliseconds;
        final raw =
            (dragging.value ?? posSnapshot.data!.inMilliseconds.toDouble())
                .clamp(0.0, total.toDouble());
        return Column(
          children: [
            Slider(
              value: total == 0 ? 0.0 : raw,
              max: total == 0 ? 1 : total.toDouble(),
              onChanged: total == 0 ? null : (value) => dragging.value = value,
              onChangeEnd: total == 0
                  ? null
                  : (value) {
                      controller.player
                          .seek(Duration(milliseconds: value.toInt()));
                      dragging.value = null;
                    },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatSongDuration(Duration(milliseconds: raw.toInt())),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(formatSongDuration(duration),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
