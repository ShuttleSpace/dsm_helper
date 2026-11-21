import 'dart:async';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/nfo_util.dart';
import 'package:garden/util/tmdb_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/widgets/folder_picker_sheet.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:url_launcher/url_launcher_string.dart';

class VideoPlayerPage extends HookWidget {
  final String? name;
  final String url;
  final String? cover;
  final String? nfo;
  final bool network;

  /// 同目录下的字幕旁车文件路径（NAS 上的 path），可空。
  final List<String> subtitles;

  /// NAS 上的视频 path，用来记续播位置；为 null 就不记。
  final String? mediaPath;

  /// 同一个列表里的其它片子，用来上一个/下一个和自动连播。
  final List<MediaItem> playlist;
  const VideoPlayerPage(
      {super.key,
      required this.url,
      this.name,
      this.cover,
      this.nfo,
      this.subtitles = const [],
      this.mediaPath,
      this.playlist = const [],
      this.network = true});

  @override
  Widget build(BuildContext context) {
    final player = useMemoized(() => Player(), const []);
    final videoController = useMemoized(
      () => VideoController(player,
          configuration: const VideoControllerConfiguration(
              enableHardwareAcceleration: true)),
      const [],
    );
    final isInitialized = useSignal(false);
    final videoAspectRatio = useSignal(1.0);
    final description = useSignal("");
    final date = useSignal("");
    final year = useSignal('');
    final actors = useSignal<List>([]);
    final currentSpeed = useSignal(1.0);
    final subtitleFontSize = useState(16.0);
    final genres = useSignal('');
    final directors = useSignal('');
    final runtime = useSignal('');
    final rating = useSignal('');
    final premiered = useSignal('');
    final poster = useSignal('');
    final tmdbUsed = useSignal(false);
    // 播放列表切换时这几项要跟着变，所以不能只读构造参数
    final currentName = useSignal(name ?? '');
    final currentUrl = useSignal(url);
    final currentCover = useSignal(cover ?? '');
    final currentNfo = useSignal(nfo);
    final currentSubtitles = useSignal<List<String>>(subtitles);
    final currentPath = useSignal(mediaPath);
    final playingIndex =
        useSignal(playlist.indexWhere((e) => e.path == (mediaPath ?? '')));
    final autoNext = useState(true);

    // 倍速列表
    const Map<String, double> speedList = {
      "2.0": 2.0,
      "1.5": 1.5,
      "1.0": 1.0,
      "0.5": 0.5,
    };

    /// 打开当前这一部：开播、续播定位、挂外置字幕。切换列表时复用。
    Future<void> openCurrent() async {
      try {
        // 等待 open 完成，失败才能落到下面的 catch（原来未 await 永远不进 catch）。
        await player.open(Media(currentUrl.value), play: true);
        // 续播：上次看到一半的位置
        final resume = await resumePosition(currentPath.value ?? '');
        if (resume != null) await player.seek(resume);
        isInitialized.value = true;
        // 外置字幕：mpv 的 sub-add，多个文件都进轨道列表供用户切换。
        // 单独 try：字幕加载失败不能当成视频加载失败。
        try {
          for (final path in currentSubtitles.value) {
            await player.setSubtitleTrack(SubtitleTrack.uri(
              fbDownloadUrl(
                baseUri: connectionStore.baseUri.value,
                path: path,
                sid: connectionStore.sid.value,
                mode: 'open',
              ),
              title: path.split('/').last,
            ));
          }
        } catch (e) {
          Log.error("字幕加载异常: $e");
        }
      } catch (error) {
        Log.error("播放初始化异常: $error");
        UiUtil.toast("视频加载失败：$error，请尝试使用第三方播放器");
      }
    }

    Future<void> changeSpeed(double speed) async {
      currentSpeed.value = speed;
      player.setPitch(speed);
    }

    parseNfo(String? nfo) async {
      if (nfo == null) return;
      try {
        final nfoUrl = fbDownloadUrl(
          baseUri: connectionStore.baseUri.value,
          path: nfo!,
          sid: connectionStore.sid.value,
          mode: 'open',
        );
        final bytes = await fetchFileBytes(nfoUrl);
        final nfoDetail = parseNfoDetail(utf8.decode(bytes));
        if (nfoDetail == null) return;
        description.value = nfoDetail['plot'] ?? '';
        date.value = nfoDetail['dateadded'] ?? '';
        actors.value = nfoDetail['actor'] ?? [];
        year.value = nfoDetail['year'] ?? '';
        genres.value = joinNfoNames(nfoDetail['genre']);
        directors.value = joinNfoNames(nfoDetail['director']);
        runtime.value = '${nfoDetail['runtime'] ?? ''}';
        rating.value = '${nfoDetail['rating'] ?? ''}';
        premiered.value = '${nfoDetail['premiered'] ?? ''}';
        poster.value = firstNfoImage(nfoDetail['thumb']);
      } catch (e) {
        Log.error("nfo解析异常: $e");
      }
    }

    /// NFO 没提供简介时才去 TMDB 补刮；结果只填空字段，不覆盖 NFO。
    Future<void> parseTmdb() async {
      if (description.value.isNotBlank) return;
      final apiKey = await StorageUtil.getString(tmdbApiKeyStorageKey) ?? '';
      if (apiKey.isBlank) return;
      final info = await fetchTmdbInfo(apiKey, currentName.value);
      if (info == null) {
        Log.info("TMDB 未查到: $name");
        return;
      }
      if (description.value.isBlank) description.value = info.overview;
      if (year.value.isBlank) year.value = info.year;
      if (genres.value.isBlank) genres.value = info.genres;
      if (runtime.value.isBlank) runtime.value = info.runtime;
      if (rating.value.isBlank) rating.value = info.rating;
      if (premiered.value.isBlank) premiered.value = info.premiered;
      if (poster.value.isBlank) poster.value = info.poster;
      tmdbUsed.value = true;
    }

    /// 在 NAS 上挑字幕文件；复用上传时那个文件选择器（只列字幕扩展名）。
    void resetMeta() {
      description.value = '';
      date.value = '';
      year.value = '';
      actors.value = [];
      genres.value = '';
      directors.value = '';
      runtime.value = '';
      rating.value = '';
      premiered.value = '';
      poster.value = '';
      tmdbUsed.value = false;
    }

    /// 上一层记下进度，再换成列表里的第 i 部。
    Future<void> playEntry(int i) async {
      if (i < 0 || i >= playlist.length) return;
      final item = playlist[i];
      if (currentPath.value != null && item.path != currentPath.value) {
        await savePlayProgress(currentPath.value!, player.state.position,
            duration: player.state.duration);
      }
      playingIndex.value = i;
      currentName.value = item.name;
      currentPath.value = item.path;
      currentCover.value = item.coverPath;
      currentNfo.value = item.nfoPath;
      currentSubtitles.value = item.subtitles;
      currentUrl.value = fbDownloadUrl(
        baseUri: connectionStore.baseUri.value,
        path: item.path,
        sid: connectionStore.sid.value,
        mode: 'open',
      );
      resetMeta();
      await openCurrent();
      parseNfo(currentNfo.value).then((_) => parseTmdb());
    }

    bool hasNext() =>
        playingIndex.value >= 0 && playingIndex.value + 1 < playlist.length;

    Future<void> pickSubtitle() async {
      final picked = await showFolderPickerSheet(
        context,
        fileExtensions: FileTypeUtil.subtitleExtensions,
      );
      if (picked is! List || picked.isEmpty) return;
      final path = '${picked.first}';
      try {
        await player.setSubtitleTrack(SubtitleTrack.uri(
          fbDownloadUrl(
            baseUri: connectionStore.baseUri.value,
            path: path,
            sid: connectionStore.sid.value,
            mode: 'open',
          ),
          title: path.split('/').last,
        ));
      } catch (e) {
        Log.error("字幕载入异常: $e");
      }
    }

    /// 播放列表面板：点条目切片，底部一个自动连播开关。
    void showPlaylist() {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: autoNext.value,
                title: const Text('自动连播'),
                onChanged: (value) {
                  autoNext.value = value;
                  StorageUtil.setBool("auto_play_next", value);
                  (context as Element).markNeedsBuild();
                },
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlist.length,
                  itemBuilder: (context, i) {
                    final item = playlist[i];
                    final current = i == playingIndex.value;
                    return ListTile(
                      dense: true,
                      selected: current,
                      leading: Icon(current ? Icons.volume_up : Icons.movie),
                      title: Text(item.displayTitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: item.subtitleLine.isBlank
                          ? null
                          : Text(item.subtitleLine),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!current) playEntry(i);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    useEffect(() {
      StorageUtil.getInt("subtitle_font_size").then((value) {
        if (value != null) subtitleFontSize.value = value.toDouble();
      });
      return null;
    }, const []);

    useEffect(() {
      // 自动连播开关：默认开
      StorageUtil.getBool("auto_play_next").then((value) {
        if (value != null) autoNext.value = value;
      });
      final aspectSub = player.stream.videoParams.listen((event) {
        videoAspectRatio.value = event.aspect ?? 1;
      });
      // 自动连播：这一部放完就开列表里的下一部
      final completedSub = player.stream.completed.listen((done) {
        if (done && autoNext.value && hasNext()) {
          playEntry(playingIndex.value + 1);
        }
      });
      // NFO 先解析，解析不到的字段再由 TMDB 补。
      parseNfo(currentNfo.value).then((_) => parseTmdb());
      openCurrent();
      return () {
        aspectSub.cancel();
        completedSub.cancel();
        // 离开时记续播位置（离开页面时 state 还是最后一次的）
        if (currentPath.value != null) {
          savePlayProgress(currentPath.value!, player.state.position,
              duration: player.state.duration);
        }
        player.dispose();
      };
    }, const []);

    // 封面：本地 fanart/poster 优先，其次 NFO 里的 thumb（多为远程 URL）
    final posterUrl =
        currentCover.value.isNotBlank ? currentCover.value : poster.value;

    Widget infoRow(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Text("$label：$value"),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentName.value.isNotBlank ? currentName.value : '视频播放'),
        leading: AppBackButton(context),
        actions: [
          if (playlist.isNotEmpty) ...[
            IconButton(
              tooltip: '上一个',
              icon: const Icon(Icons.skip_previous),
              onPressed: playingIndex.value > 0
                  ? () => playEntry(playingIndex.value - 1)
                  : null,
            ),
            IconButton(
              tooltip: '下一个',
              icon: const Icon(Icons.skip_next),
              onPressed:
                  hasNext() ? () => playEntry(playingIndex.value + 1) : null,
            ),
          ],
          if (playlist.isNotEmpty)
            IconButton(
                tooltip: '播放列表',
                icon: const Icon(Icons.playlist_play),
                onPressed: showPlaylist),
          // 字幕选择：外置字幕（sub-add）和容器内嵌字幕都在这里
          PopupMenuButton<Object>(
            tooltip: '字幕',
            icon: const Icon(Icons.subtitles),
            onSelected: (value) {
              if (value is SubtitleTrack) {
                player.setSubtitleTrack(value);
              } else {
                pickSubtitle();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<Object>(
                  value: 'local', child: Text('选择 NAS 上的字幕…')),
              PopupMenuItem<Object>(
                  value: SubtitleTrack.no(), child: const Text('关闭字幕')),
              ...player.state.tracks.subtitle
                  .where((e) => e.id != 'auto' && e.id != 'no')
                  .map((e) => PopupMenuItem<Object>(
                        value: e,
                        child: Text(
                          e.title ?? e.language ?? '字幕 ${e.id}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 0, top: 8, bottom: 8, right: 8),
            child: OutlinedButton(
              onPressed: () async {
                player.pause();
                try {
                  if (Platform.isAndroid) {
                    await AndroidIntent(
                      action: 'action_view',
                      data: url,
                      arguments: {},
                      type: "video/*",
                    ).launch();
                  } else {
                    // vlc:// 没人接的时候 launchUrlString 只返回 false，不抛异常，
                    // 原来没人看返回值，按钮就像坏了。
                    final ok = await launchUrlString("vlc://$url");
                    if (!ok) UiUtil.toast("没找到 VLC，装了才能用外部播放器");
                  }
                } catch (e) {
                  Log.error("外部播放器调用失败: $e");
                  UiUtil.toast("外部播放器调用失败，继续用内置播放器");
                }
              },
              child: Image.asset(
                "assets/icons/player.png",
                width: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 视频播放区域
          Container(
            color: Theme.brightnessOf(context) == Brightness.dark
                ? Colors.white
                : Colors.black,
            child: isInitialized.value
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.3),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: videoAspectRatio.value,
                          child: Video(
                            controller: videoController,
                            subtitleViewConfiguration:
                                SubtitleViewConfiguration(
                              // 播放区只有屏高 30%，media_kit 默认按 1080p 缩小会让字幕小到看不清，
                              // 所以关掉缩放，字号直接用设置里的逻辑像素。
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: subtitleFontSize.value,
                                color: Colors.white,
                                backgroundColor: const Color(0xaa000000),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        // 控制面板
                        Visibility(
                          visible: false,
                          child: Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  // 控制按钮
                                  Row(
                                    children: [
                                      // 播放/暂停按钮
                                      IconButton(
                                        onPressed: () {
                                          player.playOrPause();
                                        },
                                        icon: Icon(
                                          player.state.playing
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // 时间显示
                                      Text(
                                        "${formatDuration(player.state.position)} / ${formatDuration(player.state.duration)}",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      const Spacer(),
                                      // 倍速按钮
                                      PopupMenuButton<double>(
                                        icon: Row(
                                          children: [
                                            Text(
                                              "${currentSpeed.value}x",
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            const Icon(
                                              Icons.speed,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        onSelected: (double speed) {
                                          changeSpeed(speed);
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return speedList.entries.map((entry) {
                                            return PopupMenuItem<double>(
                                              value: entry.value,
                                              child: Text(entry.key),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            Log.log(
                                "detail: ${details.delta.dx.toInt() / MediaQuery.devicePixelRatioOf(context)}");
                            player.seek(Duration(
                                milliseconds:
                                    player.state.position.inMilliseconds +
                                        (details.delta.dx.toInt() /
                                                MediaQuery.devicePixelRatioOf(
                                                    context))
                                            .toInt()));
                          },
                          onVerticalDragUpdate: (details) => {
                            // TODO: volume & brightness
                          },
                        )
                      ],
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: MediaQuery.sizeOf(context).width * 9 / 16,
                    color: Colors.black,
                    child: Center(
                      child: posterUrl.isNotBlank
                          ? ExtendedImage.network(
                              posterUrl.startsWith("http")
                                  ? posterUrl
                                  : thumbUrl(
                                      baseUri: connectionStore.baseUri.value,
                                      path: posterUrl,
                                      sid: connectionStore.sid.value,
                                    ),
                            )
                          : const CircularProgressIndicator(),
                    ),
                  ),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(
                    "注意：视频播放器目前使用官方库，如遇到黑屏、无声、卡顿等任何问题，请点击右上角按钮使用第三方播放器播放！${Platform.isIOS ? '(仅支持vlc player，请确保已安装)' : ''}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                if (currentNfo.value != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge),
                    child: Text("以下信息来源于同文件夹下NFO文件，仅做参考："),
                  ),
                const SizedBox(
                  height: 20,
                ),
                if (description.value.isNotBlank)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(description.value),
                  ),
                const SizedBox(
                  height: 10,
                ),
                if (year.value.isNotBlank)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("年份：${year.value}"),
                  ),
                const SizedBox(
                  height: 10,
                ),
                if (date.value.isNotBlank)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("添加时间：${date.value}"),
                  ),
                if (genres.value.isNotBlank) infoRow("类型", genres.value),
                if (directors.value.isNotBlank) infoRow("导演", directors.value),
                if (runtime.value.isNotBlank)
                  infoRow("片长", "${runtime.value} 分钟"),
                if (rating.value.isNotBlank) infoRow("评分", rating.value),
                if (premiered.value.isNotBlank) infoRow("首播", premiered.value),
                if (tmdbUsed.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(
                      "部分数据来自 TMDB",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                const SizedBox(
                  height: 20,
                ),
                if (actors.value.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("演员表："),
                  ),
                  ...actors.value.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text("${e['name']}"),
                          ),
                          Expanded(
                            child: Text(
                              "${e['role'] ?? ''}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
