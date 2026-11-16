import 'dart:async';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:xml2json/xml2json.dart';

class VideoPlayerPage extends HookWidget {
  final String? name;
  final String url;
  final String? cover;
  final String? nfo;
  final bool network;
  const VideoPlayerPage(
      {super.key,
      required this.url,
      this.name,
      this.cover,
      this.nfo,
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

    // 倍速列表
    const Map<String, double> speedList = {
      "2.0": 2.0,
      "1.5": 1.5,
      "1.0": 1.0,
      "0.5": 0.5,
    };

    Future<void> initializeVideo() async {
      try {
        // 等待 open 完成，失败才能落到下面的 catch（原来未 await 永远不进 catch）。
        await player.open(Media(url), play: true);
        player.stream.videoParams.listen((event) {
          videoAspectRatio.value = event.aspect ?? 1;
        });
        isInitialized.value = true;
      } catch (error) {
        Log.error("播放初始化异常: $error");
        UiUtil.toast("视频加载失败：$error，请尝试使用第三方播放器");
      }
    }

    Future<void> changeSpeed(double speed) async {
      currentSpeed.value = speed;
      player.setPitch(speed);
    }

    parseNfo() async {
      if (nfo == null) return;
      try {
        final myTransformer = Xml2Json();
        final nfoUrl = fbDownloadUrl(
          baseUri: connectionStore.baseUri.value,
          path: nfo!,
          sid: connectionStore.sid.value,
          mode: 'open',
        );
        final bytes = await fetchFileBytes(nfoUrl);
        myTransformer.parse(utf8.decode(bytes));
        var json = jsonDecode(myTransformer.toParker());
        var nfoDetail = json['episodedetails'] ?? json['movie'];
        description.value = nfoDetail['plot'] ?? '';
        date.value = nfoDetail['dateadded'] ?? '';
        actors.value = nfoDetail['actor'] ?? [];
        year.value = nfoDetail['year'] ?? '';
      } catch (e) {
        Log.error("nfo解析异常: $e");
      }
    }

    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    useEffect(() {
      parseNfo();
      initializeVideo();
      return () {
        player.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? '视频播放'),
        leading: AppBackButton(context),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(left: 0, top: 8, bottom: 8, right: 8),
            child: OutlinedButton(
              onPressed: () async {
                player.pause();
                if (Platform.isAndroid) {
                  AndroidIntent intent = AndroidIntent(
                    action: 'action_view',
                    data: url,
                    arguments: {},
                    type: "video/*",
                  );
                  await intent.launch();
                } else {
                  launchUrlString("vlc://$url");
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
                          child: Video(controller: videoController),
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
                                milliseconds: player.state.position.inMilliseconds +
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
                      child: cover != null && cover!.isNotBlank
                          ? ExtendedImage.network(
                              cover!.startsWith("http")
                                  ? cover!
                                  : thumbUrl(
                                      baseUri: connectionStore.baseUri.value,
                                      path: cover!,
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
                if (nfo != null)
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
                            child: Text("${e['role']}"),
                          ),
                          Expanded(
                            child: Text("${e['name']}"),
                          ),
                          Expanded(
                            child: Text("${e['type']}"),
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
