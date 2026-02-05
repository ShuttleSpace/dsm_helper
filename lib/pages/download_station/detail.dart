import 'package:garden/util/http_util.dart';
import 'package:garden/util/format_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'add_tracker.dart';

class DownloadDetail extends StatefulWidget {
  final String id;
  const DownloadDetail(this.id, {super.key});
  @override
  DownloadDetailState createState() => DownloadDetailState();
}

class DownloadDetailState extends State<DownloadDetail>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  bool loadingTrackers = true;
  bool loadingPeers = true;
  bool loadingFiles = true;
  List trackers = [];
  List peers = [];
  List files = [];

  bool showAddTrackerButton = false;
  dynamic task;
  @override
  void initState() {
    getData();
    super.initState();
  }

  getTrackers() async {
    var res = await Api.downloadTracker(widget.id);
    if (res['success']) {
      setState(() {
        loadingTrackers = false;
        trackers = res['data']['items'];
      });
    }
  }

  getPeers() async {
    var res = await Api.downloadPeer(widget.id);
    if (res['success']) {
      setState(() {
        loadingPeers = false;
        peers = res['data']['items'];
      });
    }
  }

  getFiles() async {
    var res = await Api.downloadFile(widget.id);
    if (res['success']) {
      setState(() {
        loadingFiles = false;
        files = res['data']['items'];
      });
    }
  }

  handleTab() {
    if (_tabController.index == 2) {
      setState(() {
        showAddTrackerButton = true;
      });
      getTrackers();
    } else {
      setState(() {
        showAddTrackerButton = false;
      });
    }
    if (_tabController.index == 3) {
      getPeers();
    }
    if (_tabController.index == 4) {
      getFiles();
    }
  }

  getData() async {
    var res = await Api.downloadDetail(widget.id);
    setState(() {
      loading = false;
      if (res['success']) {
        task = res['data']['task'][0];
        if (task['type'] == "bt" && task['status'] == 2) {
          _tabController = TabController(length: 6, vsync: this);
          _tabController.addListener(handleTab);
        } else {
          _tabController = TabController(length: 2, vsync: this);
        }
      }
    });
  }

  Widget _buildFileItem(file) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          children: [
            Text(
              "${file['name']}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Text("${FormatUtil.formatSize(file['size_downloaded'])} / "),
                Text(FormatUtil.formatSize(file['size'])),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  "${(file['size_downloaded'] * 100 / file['size']).toStringAsFixed(2)} %",
                  style: const TextStyle(color: Colors.blue),
                ),
                const Spacer(),
                Label(
                  file['priority'] == "normal"
                      ? "一般"
                      : file['priority'] == "high"
                          ? "高"
                          : "低",
                  file['priority'] == "normal"
                      ? Colors.blue
                      : file['priority'] == "high"
                          ? Colors.orange
                          : Colors.grey,
                  fill: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerItem(peer) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          children: [
            Row(
              children: [
                Text("${peer['ip']}"),
                const Spacer(),
                Text("${peer['client']}"),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Text("进度：${(peer['progress'] * 100).toStringAsFixed(0)}%"),
                const Spacer(),
                const Icon(
                  Icons.download_sharp,
                  color: Colors.green,
                  size: 16,
                ),
                Text(
                  FormatUtil.formatSize(peer['speed_download']),
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(
                  width: 10,
                ),
                const Icon(
                  Icons.upload_sharp,
                  color: Colors.blue,
                  size: 16,
                ),
                Text(
                  FormatUtil.formatSize(peer['speed_upload']),
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerItem(tracker) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${tracker['url']}"),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Text(
                  "种子数：${tracker['seeds'] >= 0 ? tracker['seeds'] : "-"}",
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  "Peer数：${tracker['peers'] >= 0 ? tracker['peers'] : "-"}",
                  style: const TextStyle(color: Colors.blue),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    "${tracker['status']}",
                    style: TextStyle(
                        color: tracker['status'] == "Success"
                            ? Colors.green
                            : Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("任务详情"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                UiUtil.vibrate(FeedbackType.warning);
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) {
                    return Material(
                      color: Colors.transparent,
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppConstants.paddingSmall),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text(
                                  "确认删除",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                const Text(
                                  "确认要删除此任务？",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(
                                  height: 22,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          var res =
                                              await Api.downloadTaskAction(
                                                  [task['id']], "delete");
                                          if (res['success']) {
                                            UiUtil.toast("任务删除成功");
                                            if (context.mounted) {
                                              // ignore: use_build_context_synchronously
                                              Navigator.of(context).pop();
                                            }
                                          } else {
                                            UiUtil.toast(
                                                "任务删除失败，代码：${res['error']['code']}");
                                          }
                                        },
                                        child: const Text(
                                          "确认删除",
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          "取消",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Image.asset(
                "assets/icons/delete.png",
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: TabBar(
                    dividerHeight: 0,
                    isScrollable: true,
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Theme.brightnessOf(context) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicator: const BubbleTabIndicator(),
                    tabs: [
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("常规"),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("传输信息"),
                      ),
                      if (task['type'] == "bt" && task['status'] == 2) ...[
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("Tracker服务器"),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("Peer数"),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("文件"),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("预览"),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ListView(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("文件名："),
                                  Expanded(
                                    child: Text(task['title']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  const Text("保存位置："),
                                  Expanded(
                                    child: Text(
                                      task['additional']['detail']
                                          ['destination'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  const Text("文件大小："),
                                  Expanded(
                                    child: Text(
                                      task['size'] > 0
                                          ? FormatUtil.formatSize(task['size'])
                                          : "未取得",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("用户名："),
                                  Text("${task['username']}"),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("网址："),
                                  Expanded(
                                      child: Text(
                                          "${task['additional']['detail']['uri']}")),
                                  OutlinedButton(
                                    onPressed: () async {
                                      ClipboardData data = ClipboardData(
                                          text: task['additional']['detail']
                                              ['uri']);
                                      Clipboard.setData(data);
                                      UiUtil.toast("已复制到剪贴板");
                                    },
                                    child: const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Icon(
                                        Icons.copy,
                                        color: AppColors.primaryAction,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("创建时间："),
                                  Text(DateTime.fromMillisecondsSinceEpoch(
                                          task['additional']['detail']
                                                  ['created_time'] *
                                              1000)
                                      .format("Y-m-d H:i:s")),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("完成时间："),
                                  Text(task['additional']['detail']
                                              ['completed_time'] >
                                          0
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                              task['additional']['detail']
                                                      ['completed_time'] *
                                                  1000)
                                          .format("Y-m-d H:i:s")
                                      : "无法取得"),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("预计等待时间："),
                                  Text(task['additional']['detail']
                                              ['waiting_seconds'] >
                                          0
                                      ? HttpUtil.instance.timeRemaining(
                                          task['additional']['detail']
                                              ['waiting_seconds'])
                                      : "无法取得"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ListView(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("状态："),
                                  Expanded(
                                    child: task['status'] == 1
                                        ? const Text(
                                            "等待中",
                                            style:
                                                TextStyle(color: Colors.grey),
                                          )
                                        : task['status'] == 2
                                            ? Text(
                                                "${FormatUtil.formatSize(task['additional']['transfer']['speed_download'])}/s",
                                                style: const TextStyle(
                                                    color:
                                                        Colors.lightBlueAccent),
                                              )
                                            : task['status'] == 3
                                                ? const Text(
                                                    "已暂停",
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  )
                                                : task['status'] == 5
                                                    ? const Text(
                                                        "已完成",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.green),
                                                      )
                                                    : task['status'] == 6
                                                        ? const Text(
                                                            "检查中",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey),
                                                          )
                                                        : task['status'] == 101
                                                            ? const Text(
                                                                "错误",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red),
                                                              )
                                                            : task['status'] ==
                                                                    105
                                                                ? const Text(
                                                                    "空间不足",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red),
                                                                  )
                                                                : task['status'] ==
                                                                        113
                                                                    ? const Text(
                                                                        "重复的任务",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red),
                                                                      )
                                                                    : Text(
                                                                        "代码：${task['status']}",
                                                                        style: const TextStyle(
                                                                            color:
                                                                                Colors.red),
                                                                      ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  const Text("已下载："),
                                  Expanded(
                                    child: Text(
                                      FormatUtil.formatSize(task['additional']
                                          ['transfer']['size_downloaded']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  const Text("已上传："),
                                  Expanded(
                                    child: Text(
                                      "${FormatUtil.formatSize(task['additional']['transfer']['size_uploaded'])} （${task['additional']['transfer']['size_downloaded'] > 0 ? (task['additional']['transfer']['size_uploaded'] / task['additional']['transfer']['size_downloaded'] * 100).toStringAsFixed(2) : "0"}%)",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  const Text("进度："),
                                  Expanded(
                                    child: Text(
                                      "${task['size'] > 0 ? (task['additional']['transfer']['size_downloaded'] / task['size'] * 100).toStringAsFixed(2) : "0"}%",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("速度："),
                                  Text(task['additional']['transfer']
                                              ['speed_download'] >
                                          0
                                      ? FormatUtil.formatSize(task['additional']
                                          ['transfer']['speed_download'])
                                      : "无法取得"),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Peer数："),
                                  Expanded(
                                      child: Text(
                                          "${task['additional']['detail']['total_peers'] > 0 ? task['additional']['detail']['total_peers'] : "无法取得"}")),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("分块总数："),
                                  Expanded(
                                      child: Text(
                                          "${task['additional']['detail']['total_pieces'] > 0 ? task['additional']['detail']['total_pieces'] : "无法取得"}")),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("已下载分块数："),
                                  Text(
                                      "${task['additional']['transfer']['downloaded_pieces']}"),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("已做种时间："),
                                  Text(HttpUtil.instance.timeRemaining(
                                      task['additional']['detail']
                                          ['seed_elapsed'])),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("开始时间："),
                                  Text(DateTime.fromMillisecondsSinceEpoch(
                                          task['additional']['detail']
                                                  ['started_time'] *
                                              1000)
                                      .format("Y-m-d H:i:s")),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("剩余时间："),
                                  Text(task['additional']['transfer']
                                              ['speed_download'] >
                                          0
                                      ? HttpUtil.instance.timeRemaining(
                                          ((task['size'] -
                                                      task['additional']
                                                              ['transfer']
                                                          ['size_downloaded']) /
                                                  task['additional']['transfer']
                                                      ['speed_download'])
                                              .ceil())
                                      : "无法取得"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task['type'] == "bt" && task['status'] == 2) ...[
                        loadingTrackers
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 14,
                                ),
                              )
                            : trackers.isEmpty
                                ? const Center(
                                    child: Text("无Tracker"),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return _buildTrackerItem(trackers[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return const SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: trackers.length),
                        loadingPeers
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 14,
                                ),
                              )
                            : peers.isEmpty
                                ? const Center(
                                    child: Text("无Peer"),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return _buildPeerItem(peers[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return const SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: peers.length),
                        loadingFiles
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 14,
                                ),
                              )
                            : files.isEmpty
                                ? const Center(
                                    child: Text("无文件"),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return _buildFileItem(files[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return const SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: files.length),
                        const Center(
                          child: Text("暂不支持预览"),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: showAddTrackerButton
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(
                        builder: (context) {
                          return AddTracker(widget.id);
                        },
                        settings: const RouteSettings(name: "add_tracker")))
                    .then((res) {
                  if (res != null && res) {
                    getTrackers();
                  }
                });
              },
            )
          : null,
    );
  }
}
