import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/extensions/int.dart';
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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class DownloadDetail extends HookWidget {
  final String id;
  const DownloadDetail(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final loading = useSignal(true);
    final loadingTrackers = useSignal(true);
    final loadingPeers = useSignal(true);
    final loadingFiles = useSignal(true);
    final trackers = useSignal<List>([]);
    final peers = useSignal<List>([]);
    final files = useSignal<List>([]);
    final showAddTrackerButton = useSignal(false);
    final task = useSignal<dynamic>(null);

    // The tab count depends on the task type, which is only known after the
    // first fetch: a running torrent gets 6 tabs, anything else 2. The
    // controller is recreated (and the old one disposed) when that changes,
    // like the original setState did.
    final isRunningTorrent = task.value != null &&
        task.value['type'] == "bt" &&
        task.value['status'] == 2;
    final tabController = useMemoized(
      () => TabController(
        length: isRunningTorrent ? 6 : 2,
        vsync: tickerProvider,
      ),
      [isRunningTorrent],
    );

    Future<void> getTrackers() async {
      try {
        final data = await dsmDownloadStation2TaskBTTrackerList(taskId: id);
        trackers.value = data['items'] ?? [];
      } catch (e) {
        // 旧层失败时静默，这里保持一致。
      } finally {
        loadingTrackers.value = false;
      }
    }

    Future<void> getPeers() async {
      try {
        final data = await dsmDownloadStation2TaskBTPeerList(taskId: id);
        peers.value = data['items'] ?? [];
      } catch (e) {
        // 同上。
      } finally {
        loadingPeers.value = false;
      }
    }

    Future<void> getFiles() async {
      try {
        final data = await dsmDownloadStation2TaskBTFileList(taskId: id);
        files.value = data['items'] ?? [];
      } catch (e) {
        // 同上。
      } finally {
        loadingFiles.value = false;
      }
    }

    handleTab() {
      if (tabController.index == 2) {
        showAddTrackerButton.value = true;
        getTrackers();
      } else {
        showAddTrackerButton.value = false;
      }
      if (tabController.index == 3) {
        getPeers();
      }
      if (tabController.index == 4) {
        getFiles();
      }
    }

    Future<void> getData() async {
      try {
        final data = await dsmDownloadStation2TaskDetail(id);
        final tasks = data['task'] as List? ?? const [];
        if (tasks.isNotEmpty) task.value = tasks[0];
      } catch (e) {
        // 旧层失败时 task 保持 null，这里保持一致。
      } finally {
        // Set last so the first post-loading build already has the task.
        loading.value = false;
      }
    }

  Widget buildFileItem(file) {
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
                Text("${file['size_downloaded'].formatSize()} / "),
                Text(file['size'].formatSize()),
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

  Widget buildPeerItem(peer) {
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
                  peer['speed_download'].formatSize(),
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
                  peer['speed_upload'].formatSize(),
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTrackerItem(tracker) {
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

    useEffect(() {
      getData();
      return null;
    }, const []);

    useEffect(() {
      tabController.addListener(handleTab);
      return () {
        tabController.removeListener(handleTab);
        tabController.dispose();
      };
    }, [tabController]);

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
                    return SizedBox(
                      width: double.infinity,
                      child: Material(
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
                                          try {
                                            await dsmDownloadStation2TaskAction(
                                                [task.value['id']], "delete");
                                            UiUtil.toast("任务删除成功");
                                            if (context.mounted) {
                                              // ignore: use_build_context_synchronously
                                              Navigator.of(context).pop();
                                            }
                                          } catch (e) {
                                            final code =
                                                e is DSMException ? e.code : -1;
                                            UiUtil.toast("任务删除失败，代码：$code");
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
      body: loading.value
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
                    controller: tabController,
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
                      if (task.value['type'] == "bt" && task.value['status'] == 2) ...[
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
                    controller: tabController,
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
                                    child: Text(task.value['title']),
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
                                      task.value['additional']['detail']
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
                                      task.value['size'] > 0
                                          ? task.value['size'].formatSize()
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
                                  Text("${task.value['username']}"),
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
                                          "${task.value['additional']['detail']['uri']}")),
                                  OutlinedButton(
                                    onPressed: () async {
                                      ClipboardData data = ClipboardData(
                                          text: task.value['additional']['detail']
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
                                          task.value['additional']['detail']
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
                                  Text(task.value['additional']['detail']
                                              ['completed_time'] >
                                          0
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                              task.value['additional']['detail']
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
                                  Text(task.value['additional']['detail']
                                              ['waiting_seconds'] >
                                          0
                                      ? (int.parse(task.value['additional']['detail']
                                              ['waiting_seconds']))
                                          .timeRemaining()
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
                                    child: task.value['status'] == 1
                                        ? const Text(
                                            "等待中",
                                            style:
                                                TextStyle(color: Colors.grey),
                                          )
                                        : task.value['status'] == 2
                                            ? Text(
                                                "${task.value['additional']['transfer']['speed_download'].formatSize()}/s",
                                                style: const TextStyle(
                                                    color:
                                                        Colors.lightBlueAccent),
                                              )
                                            : task.value['status'] == 3
                                                ? const Text(
                                                    "已暂停",
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  )
                                                : task.value['status'] == 5
                                                    ? const Text(
                                                        "已完成",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.green),
                                                      )
                                                    : task.value['status'] == 6
                                                        ? const Text(
                                                            "检查中",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey),
                                                          )
                                                        : task.value['status'] == 101
                                                            ? const Text(
                                                                "错误",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red),
                                                              )
                                                            : task.value['status'] ==
                                                                    105
                                                                ? const Text(
                                                                    "空间不足",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red),
                                                                  )
                                                                : task.value['status'] ==
                                                                        113
                                                                    ? const Text(
                                                                        "重复的任务",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red),
                                                                      )
                                                                    : Text(
                                                                        "代码：${task.value['status']}",
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
                                      task.value['additional']['transfer']
                                              ['size_downloaded']
                                          .formatSize(),
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
                                      "${task.value['additional']['transfer']['size_uploaded'].formatSize()} （${task.value['additional']['transfer']['size_downloaded'] > 0 ? (task.value['additional']['transfer']['size_uploaded'] / task.value['additional']['transfer']['size_downloaded'] * 100).toStringAsFixed(2) : "0"}%)",
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
                                      "${task.value['size'] > 0 ? (task.value['additional']['transfer']['size_downloaded'] / task.value['size'] * 100).toStringAsFixed(2) : "0"}%",
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
                                  Text(task.value['additional']['transfer']
                                              ['speed_download'] >
                                          0
                                      ? task.value['additional']['transfer']
                                              ['speed_download']
                                          .formatSize()
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
                                          "${task.value['additional']['detail']['total_peers'] > 0 ? task.value['additional']['detail']['total_peers'] : "无法取得"}")),
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
                                          "${task.value['additional']['detail']['total_pieces'] > 0 ? task.value['additional']['detail']['total_pieces'] : "无法取得"}")),
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
                                      "${task.value['additional']['transfer']['downloaded_pieces']}"),
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
                                  Text((int.parse(task.value['additional']['detail']
                                          ['seed_elapsed']))
                                      .timeRemaining()),
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
                                          task.value['additional']['detail']
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
                                  Text(task.value['additional']['transfer']
                                              ['speed_download'] >
                                          0
                                      ? (int.parse(((task.value['size'] -
                                                      task.value['additional']
                                                              ['transfer']
                                                          ['size_downloaded']) /
                                                  task.value['additional']['transfer']
                                                      ['speed_download'])
                                              .ceil()))
                                          .timeRemaining()
                                      : "无法取得"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task.value['type'] == "bt" && task.value['status'] == 2) ...[
                        loadingTrackers.value
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 14,
                                ),
                              )
                            : trackers.value.isEmpty
                                ? const Center(
                                    child: Text("无Tracker"),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return buildTrackerItem(trackers.value[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return const SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: trackers.value.length),
                        loadingPeers.value
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 14,
                                ),
                              )
                            : peers.value.isEmpty
                                ? const Center(
                                    child: Text("无Peer"),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return buildPeerItem(peers.value[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return const SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: peers.value.length),
                        loadingFiles.value
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 14,
                                ),
                              )
                            : files.value.isEmpty
                                ? const Center(
                                    child: Text("无文件"),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return buildFileItem(files.value[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return const SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: files.value.length),
                        const Center(
                          child: Text("暂不支持预览"),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: showAddTrackerButton.value
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(
                        builder: (context) {
                          return AddTracker(id);
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
