import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/pages/media/music_player_page.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/music_library.dart';
import 'package:garden/widgets/embedded_cover.dart';
import 'package:garden/util/music_player_controller.dart';
import 'package:garden/util/ui_util.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 音乐列表 + 底部 mini player。点歌就在这儿放，点 mini player 进全屏页。
class MediaMusic extends HookWidget {
  final MusicPlayerController controller;
  const MediaMusic({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final songs = useSignal<List<MusicSong>>([]);
    final loading = useSignal(true);
    final failed = useSignal('');
    final sort = useSignal(MusicSort.title);

    Future<void> reload() async {
      loading.value = true;
      failed.value = '';
      try {
        final dirs = await loadMusicLibraryPaths();
        songs.value = await loadMusicLibrary(dirs: dirs);
      } catch (e) {
        Log.error("拉音乐库失败: $e");
        failed.value = '$e';
        UiUtil.toast("拉音乐库失败，NAS 上装 Audio Station 才能读标签");
        songs.value = [];
      }
      loading.value = false;
    }

    useEffect(() {
      reload();
      return null;
    }, const []);

    Widget row(MusicSong song, int i, List<MusicSong> queue) => ListTile(
          leading: _cover(song, 44),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: song.subtitleLine.isBlank
              ? null
              : Text(song.subtitleLine,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(formatSongDuration(song.duration),
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          selected: song.path == controller.current?.path,
          onTap: () => controller.play(queue, i),
        );

    // controller 里的队列/下标是 signal，必须在 Watch 里读才会重建
    return Watch((context) {
      final sorted = sortMusicSongs(songs.value, sort.value);
      return Column(
        children: [
          if (loading.value)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (sorted.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    failed.value.isBlank
                        ? '没有歌。到「多媒体设置 → 音乐目录」里选一下目录，\n或者 NAS 上先装 Audio Station。'
                        : '拉不到音乐库：${failed.value}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text('共 ${sorted.length} 首',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
                      const Spacer(),
                      PopupMenuButton<MusicSort>(
                        tooltip: '排序',
                        icon: const Icon(Icons.sort, size: 20),
                        initialValue: sort.value,
                        onSelected: (value) => sort.value = value,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: MusicSort.title, child: Text('按歌名')),
                          PopupMenuItem(
                              value: MusicSort.artist, child: Text('按艺人')),
                          PopupMenuItem(
                              value: MusicSort.album, child: Text('按专辑')),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: reload,
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, i) => row(sorted[i], i, sorted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (controller.current != null)
            _MiniPlayer(controller: controller, song: controller.current!),
        ],
      );
    });
  }
}

Widget _cover(MusicSong song, double size) =>
    EmbeddedCover(song: song, size: size);

class _MiniPlayer extends StatelessWidget {
  final MusicPlayerController controller;
  final MusicSong song;
  const _MiniPlayer({required this.controller, required this.song});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(
            builder: (_) => MusicPlayerPage(controller: controller))),
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              const SizedBox(width: 10),
              _cover(song, 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                    Text(
                      song.subtitleLine.isBlank ? '未知艺人' : song.subtitleLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              StreamBuilder<bool>(
                stream: controller.player.stream.playing,
                initialData: controller.player.state.playing,
                builder: (context, snapshot) => IconButton(
                  tooltip: snapshot.data == true ? '暂停' : '播放',
                  icon: Icon(snapshot.data == true
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill),
                  iconSize: 32,
                  onPressed: controller.toggle,
                ),
              ),
              IconButton(
                tooltip: '下一首',
                icon: const Icon(Icons.skip_next),
                onPressed: controller.hasNext ? controller.next : null,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
