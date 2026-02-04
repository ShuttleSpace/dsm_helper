import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:garden/util/function.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:xml2json/xml2json.dart';

class VideoPlayerPage extends StatefulWidget {
  final String? name;
  final String url;
  final String? cover;
  final String? nfo;
  final bool network;
  VideoPlayerPage(
      {required this.url,
      this.name,
      this.cover,
      this.nfo,
      this.network = true});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

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
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      await _controller.initialize();

      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });

      // 自动播放
      await _controller.play();

      setState(() {
        _isInitialized = true;
      });
    } catch (error) {
      print("播放初始化异常: $error");
      Util.instance.toast("视频加载失败，请尝试使用第三方播放器");
    }
  }

  Future<void> _changeSpeed(double speed) async {
    setState(() {
      _currentSpeed = speed;
    });
    await _controller.setPlaybackSpeed(speed);
  }

  parseNfo() async {
    if (widget.nfo != null) {
      final myTransformer = Xml2Json();
      String nfoUrl = Util.instance.baseUrl +
          "/fbdownload/info.nfo?dlink=%22${Util.instance.utf8Encode(widget.nfo ?? '')}%22&_sid=%22${Util.instance.sid}%22&mode=open";
      var res = await Util.instance.get(nfoUrl, decode: false);
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
      } catch (e) {}
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
            padding: EdgeInsets.only(left: 0, top: 8, bottom: 8, right: 8),
            child: OutlinedButton(
              onPressed: () async {
                _controller.pause();
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
            color: Colors.black,
            child: _isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      // 控制面板
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          child: Column(
                            children: [
                              // 进度条
                              VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: Theme.of(context).primaryColor,
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              SizedBox(height: 10),
                              // 控制按钮
                              Row(
                                children: [
                                  // 播放/暂停按钮
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_controller.value.isPlaying) {
                                          _controller.pause();
                                        } else {
                                          _controller.play();
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // 时间显示
                                  Text(
                                    "${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Spacer(),
                                  // 倍速按钮
                                  PopupMenuButton<double>(
                                    icon: Row(
                                      children: [
                                        Text(
                                          "${_currentSpeed}x",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Icon(
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
                      // 点击播放/暂停
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                      ),
                    ],
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
                                  : Util.instance.baseUrl +
                                      "/webapi/entry.cgi?path=${Uri.encodeComponent(widget.cover!)}&size=original&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${Util.instance.sid}&animate=true",
                            )
                          : CircularProgressIndicator(),
                    ),
                  ),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "注意：视频播放器目前使用官方库，如遇到黑屏、无声、卡顿等任何问题，请点击右上角按钮使用第三方播放器播放！${Platform.isIOS ? '(仅支持vlc player，请确保已安装)' : ''}",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                if (widget.nfo != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("以下信息来源于同文件夹下NFO文件，仅做参考："),
                  ),
                SizedBox(
                  height: 20,
                ),
                if (description.isNotBlank)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(description),
                  ),
                SizedBox(
                  height: 10,
                ),
                if (year.isNotBlank)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("年份：$year"),
                  ),
                SizedBox(
                  height: 10,
                ),
                if (date.isNotBlank)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text("添加时间：$date"),
                  ),
                SizedBox(
                  height: 20,
                ),
                if (actors.length > 0) ...[
                  Padding(
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
    super.dispose();
    _controller.dispose();
  }
}