import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/pages/download/download_setting.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/widgets/download/download_app_bar_widget.dart';
import 'package:garden/widgets/transfer_list.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class DownloadInfo {
  DownloadTask task;
  TaskStatus? status;
  int? progress;

  DownloadInfo({
    required this.task,
  });
  factory DownloadInfo.formTask(DownloadTask task) {
    return DownloadInfo(task: task);
  }
  @override
  String toString() =>
      "DownloadInfo(taskId: ${task.taskId}, status: $status, progress: $progress, url: ${task.taskId}, filename: ${task.filename}, savedDir: ${task.directory}, timeCreated: ${task.creationTime.toIso8601String()})";
}

/// 传输页：上传/下载任务统一由 [transferStore] 驱动，按 5 个 tab 过滤。
class Download extends HookWidget {
  const Download({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = DownloadStateInherited.of(context)!.notifier;
    final loading = useExistingSignal(notifier.loading);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.init();
      });
      return notifier.unbindBackgroundIsolate;
    }, const []);

    const tabs = <Widget>[
      Tab(text: "全部"),
      Tab(text: "下载"),
      Tab(text: "上传"),
      Tab(text: "失败"),
      Tab(text: "完成"),
    ];

    return Scaffold(
      appBar: DownloadAppBarWidget(
        multiSelect: notifier.multiSelect,
        downloadPath: notifier.downloadPath,
        onExitMultiSelect: () {
          notifier.multiSelect.value = false;
          notifier.resetSelectedTasks();
        },
        onSelectAll: () {
          notifier.resetSelectedTasks();
          notifier.addSelectedTasks(notifier.tasks.value);
        },
        onOpenSettings: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => const DownloadSetting(),
              settings: const RouteSettings(name: "download_setting"),
            ),
          );
        },
      ),
      body: loading.value
          ? const Center(child: CupertinoActivityIndicator())
          : const DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  TabBar(tabs: tabs),
                  Expanded(
                    child: TabBarView(
                      children: [
                        TransferList(),
                        TransferList(type: TransferType.download),
                        TransferList(
                          type: TransferType.upload,
                          emptyText: "暂无上传任务",
                        ),
                        TransferList(
                          state: TransferState.error,
                          emptyText: "暂无失败任务",
                        ),
                        TransferList(
                          state: TransferState.done,
                          emptyText: "暂无完成任务",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
