import 'dart:async';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:xml2json/xml2json.dart';

class VideoPlayerPage extends StatefulWidget {
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
  VideoPlayerPageState createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late final _player = Player();
  late final _videoController = VideoController(_player,
      configuration:
          const VideoControllerConfiguration(enableHardwareAcceleration: true));
  bool _isInitialized = false;
  double _videoAspectRatio = 1;

  String description = "";
  String date = "";
  String year = '';
  List actors = [];
  Map<String, dynamic> nfoDetail = {};

  // 倍速列表
  Map<String, double> speedList = {
    "2.0": 2.0,
    "1.5": 1.5,
    "1.0": 1.0,
    "0.5": 0.5,
  };

  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    parseNfo();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // 自动播放
      _player.open(Media(widget.url), play: true);
      _player.stream.videoParams.listen((event) {
        setState(() {
          _videoAspectRatio = event.aspect ?? 1;
        });
      });
      setState(() {
        _isInitialized = true;
      });
    } catch (error) {
      Log.log("播放初始化异常: $error");
      UiUtil.toast("视频加载失败，请尝试使用第三方播放器");
    }
  }

  Future<void> _changeSpeed(double speed) async {
    setState(() {
      _currentSpeed = speed;
    });
    _player.setPitch(speed);
  }

  parseNfo() async {
    if (widget.nfo != null) {
      final myTransformer = Xml2Json();
      String nfoUrl =
          "${connectionStore.baseUri}/fbdownload/info.nfo?dlink=%22${widget.nfo?.utf8()}%22&_sid=%22${connectionStore.sid}%22&mode=open";
      var res = await HttpUtil.instance.get(nfoUrl, decode: false);
      try {
        myTransformer.parse(res);
        var json = jsonDecode(myTransformer.toParker());
        setState(() {
          nfoDetail = json['episodedetails'] ?? json['movie'];
          description = nfoDetail['plot'] ?? '';
          date = nfoDetail['dateadded'] ?? '';
          actors = nfoDetail['actor'] ?? [];
          year = nfoDetail['year'] ?? '';
        });
      } catch (e) {
        Log.log("nfo解析异常: $e");
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name ?? '视频播放'),
        leading: AppBackButton(context),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(left: 0, top: 8, bottom: 8, right: 8),
            child: OutlinedButton(
              onPressed: () async {
                _player.pause();
                if (Platform.isAndroid) {
                  AndroidIntent intent = AndroidIntent(
                    action: 'action_view',
                    data: widget.url,
                    arguments: {},
                    type: "video/*",
                  );
                  await intent.launch();
                } else {
                  launchUrlString("vlc://${widget.url}");
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
            child: _isInitialized
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.3),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoAspectRatio,
                          child: Video(controller: _videoController),
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
                                          setState(() {
                                            _player.playOrPause();
                                          });
                                        },
                                        icon: Icon(
                                          _player.state.playing
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // 时间显示
                                      Text(
                                        "${_formatDuration(_player.state.position)} / ${_formatDuration(_player.state.duration)}",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      const Spacer(),
                                      // 倍速按钮
                                      PopupMenuButton<double>(
                                        icon: Row(
                                          children: [
                                            Text(
                                              "${_currentSpeed}x",
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
                                          _changeSpeed(speed);
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
                            _player.seek(Duration(
                                milliseconds:
                                    _player.state.position.inMilliseconds +
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
                      child: widget.cover != null && widget.cover!.isNotBlank
                          ? ExtendedImage.network(
                              widget.cover!.startsWith("http")
                                  ? widget.cover!
                                  : "${connectionStore.baseUri}/webapi/entry.cgi?path=${Uri.encodeComponent(widget.cover!)}&size=original&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${connectionStore.sid}&animate=true",
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
                if (widget.nfo != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge),
                    child: Text("以下信息来源于同文件夹下NFO文件，仅做参考："),
                  ),
                const SizedBox(
                  height: 20,
                ),
                if (description.isNotBlank)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(description),
                  ),
                const SizedBox(
                  height: 10,
                ),
                if (year.isNotBlank)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("年份：$year"),
                  ),
                const SizedBox(
                  height: 10,
                ),
                if (date.isNotBlank)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("添加时间：$date"),
                  ),
                const SizedBox(
                  height: 20,
                ),
                if (actors.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("演员表："),
                  ),
                  ...actors.map(
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

  @override
  void dispose() async {
    await _player.dispose();
    super.dispose();
  }
}
