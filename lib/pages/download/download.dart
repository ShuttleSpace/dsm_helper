import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:garden/pages/download/download_setting.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:garden/widgets/bottom_option_sheet.dart';
import 'package:garden/widgets/bottom_sheet_card.dart';
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

const _emptyText = <String>[
  '暂无传输任务',
  '暂无下载任务',
  '暂无上传任务',
  '暂无失败任务',
  '暂无完成任务',
];

/// 传输页：上传/下载任务统一由 [transferStore] 驱动，按 5 个 tab 过滤。
class Download extends HookWidget {
  const Download({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = DownloadStateInherited.of(context)!.notifier;
    final loading = useExistingSignal(notifier.loading);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.init());
      return notifier.unbindBackgroundIsolate;
    }, const []);

    final query = useSignal('');
    final sort = useSignal(TransferSort.created);
    final ascending = useSignal(false);
    final groupByDate = useSignal(true);
    final selectedIds = useSignal<Set<String>>({});
    final searchController = useTextEditingController();
    final tickerProvider = useMemoized(() => _DownloadTickerProvider(), const []);
    final tabController = useMemoized(
      () => TabController(length: 5, vsync: tickerProvider),
      const [],
    );
    useExistingSignal(transferStore.tasks).watch(context);
    useExistingSignal(notifier.multiSelect).watch(context);
    selectedIds.watch(context);
    query.watch(context);
    sort.watch(context);
    ascending.watch(context);
    groupByDate.watch(context);

    final multiSelect = notifier.multiSelect;
    final currentIds = selectedIds.value;
    final selectedTasks = transferStore.tasks.value
        .where((t) => currentIds.contains(t.id))
        .toList();

    void exitMultiSelect() {
      multiSelect.value = false;
      selectedIds.value = {};
    }

    void toggleSelected(String id) {
      final next = {...selectedIds.value};
      if (!next.remove(id)) next.add(id);
      selectedIds.value = next;
    }

    void enterMultiSelect(String id) {
      multiSelect.value = true;
      selectedIds.value = {id};
    }

    void toggleGroupByDate() {
      if (sort.value == TransferSort.name) {
        UiUtil.toast('名称排序不支持分组');
        return;
      }
      groupByDate.value = !groupByDate.value;
    }

    void openSettings() {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const DownloadSetting(),
          settings: const RouteSettings(name: "download_setting"),
        ),
      );
    }

    Future<void> clearTasks(Iterable<TransferTask> targets) async {
      for (final t in targets) {
        await transferStore.deleteTask(t);
      }
    }

    void confirmClear(String title, String label, Iterable<TransferTask> targets) {
      if (targets.isEmpty) {
        UiUtil.toast('暂无任务');
        return;
      }
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomConfirmSheet(
          title: title,
          content: '${targets.length} 个任务',
          confirmText: label,
          cancelText: '返回',
          onConfirm: () async {
            await clearTasks(targets);
            if (context.mounted) exitMultiSelect();
            UiUtil.toast('已清空');
          },
        ),
      );
    }

    void openClearMenu() {
      final tasks = transferStore.tasks.value;
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomOptionSheet(
          title: '清空',
          options: [
            BottomOption(
              title: '全部',
              onPressed: () => confirmClear('清空全部', '清空', tasks),
            ),
            BottomOption(
              title: '下载',
              onPressed: () => confirmClear(
                '清空下载',
                '清空',
                tasks.where((t) => t.type == TransferType.download),
              ),
            ),
            BottomOption(
              title: '上传',
              onPressed: () => confirmClear(
                '清空上传',
                '清空',
                tasks.where((t) => t.type == TransferType.upload),
              ),
            ),
            BottomOption(
              title: '完成项',
              onPressed: () => confirmClear(
                '清空完成项',
                '清空',
                tasks.where((t) => t.state == TransferState.done),
              ),
            ),
            BottomOption(
              title: '剩余项',
              onPressed: () => confirmClear(
                '清空剩余项',
                '清空',
                tasks.where((t) => t.state != TransferState.done),
              ),
            ),
          ],
        ),
      );
    }

    void openMoreMenu() {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomOptionSheet(
          title: '更多',
          options: [
            BottomOption(
              title: '排序',
              onPressed: () => showSortSheet(context, sort, ascending, groupByDate),
            ),
            BottomOption(
              title: groupByDate.value ? '取消分组' : '按日期分组',
              onPressed: toggleGroupByDate,
            ),
            BottomOption(title: '下载设置', onPressed: openSettings),
            BottomOption(title: '清空', onPressed: openClearMenu),
          ],
        ),
      );
    }

    void confirmBatch(String label, Future<void> Function() action) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomConfirmSheet(
          title: label == '取消' ? '取消任务' : '移除任务',
          content: '${selectedTasks.length} 个任务',
          confirmText: label,
          cancelText: '返回',
          onConfirm: () async {
            await action();
            if (context.mounted) exitMultiSelect();
          },
        ),
      );
    }

    Future<void> batchPause() async {
      for (final t in selectedTasks) {
        await transferStore.pauseTask(t.id);
      }
      UiUtil.toast('已暂停 ${selectedTasks.length} 项');
    }

    Future<void> batchResume() async {
      for (final t in selectedTasks) {
        await transferStore.resumeTask(t.id);
      }
      UiUtil.toast('已继续 ${selectedTasks.length} 项');
    }

    Future<void> batchCancel() async {
      for (final t in selectedTasks) {
        await transferStore.cancelTask(t.id);
      }
      UiUtil.toast('已取消 ${selectedTasks.length} 项');
    }

    Future<void> batchRemove() async {
      for (final t in selectedTasks) {
        await transferStore.deleteTask(t);
      }
      UiUtil.toast('已移除 ${selectedTasks.length} 项');
    }

    void openBatchMenu() {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomOptionSheet(
          title: '批量操作',
          options: [
            BottomOption(title: '暂停', onPressed: batchPause),
            BottomOption(title: '继续', onPressed: batchResume),
            BottomOption(
              title: '取消任务',
              onPressed: () => confirmBatch('取消', batchCancel),
            ),
            BottomOption(
              title: '移除',
              onPressed: () => confirmBatch('移除', batchRemove),
            ),
          ],
        ),
      );
    }

    final tasks = transferStore.tasks.value;
    int count(TransferType type) =>
        tasks.where((t) => t.type == type).length;
    Widget tabLabel(String label, int count) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        );
    final tabs = <Widget>[
      const Tab(text: "全部"),
      Tab(child: tabLabel('下载', count(TransferType.download))),
      Tab(child: tabLabel('上传', count(TransferType.upload))),
      const Tab(text: "失败"),
      const Tab(text: "完成"),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: multiSelect.value
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: '退出多选',
                onPressed: exitMultiSelect,
              )
            : null,
        title: multiSelect.value
            ? Text('已选 ${selectedTasks.length} 项',
                style: const TextStyle(fontSize: 16))
            : SizedBox(
                height: 40,
                child: TextField(
                  controller: searchController,
                  onChanged: (v) => query.value = v,
                  decoration: InputDecoration(
                    hintText: '搜索任务',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: query.value.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              searchController.clear();
                              query.value = '';
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
              ),
        actions: multiSelect.value
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: '全选',
                  onPressed: () {
                    selectedIds.value =
                        transferStore.tasks.value.map((t) => t.id).toSet();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: '操作',
                  onPressed: openBatchMenu,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: '更多',
                  onPressed: openMoreMenu,
                ),
              ],
      ),
      body: loading.value
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                TabBar(
                  controller: tabController,
                  tabs: tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      for (var i = 0; i < 5; i++)
                        TransferList(
                          tab: i,
                          type: transferTabType(i),
                          state: transferTabState(i),
                          emptyText: _emptyText[i],
                          query: query.value,
                          sort: sort.value,
                          ascending: ascending.value,
                          groupByDate: groupByDate.value,
                          multiSelect: multiSelect.value,
                          selectedIds: selectedIds.value,
                          onSelect: toggleSelected,
                          onLongPress: enterMultiSelect,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DownloadTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void showSortSheet(
  BuildContext context,
  Signal<TransferSort> sort,
  Signal<bool> ascending,
  Signal<bool> groupByDate,
) {
  showCupertinoModalPopup(
    context: context,
    builder: (context) => BottomSheetCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('排序', style: TextStyle(fontSize: 18)),
          ),
          for (final option in TransferSort.values)
            ListTile(
              title: Text(_sortLabel(option)),
              trailing: sort.value == option ? const Icon(Icons.check) : null,
              onTap: () {
                sort.value = option;
                if (option == TransferSort.name) groupByDate.value = false;
                Navigator.of(context).pop();
              },
            ),
          ListTile(
            title: Text(ascending.value ? '由小至大' : '由大至小'),
            trailing: const Icon(Icons.swap_vert),
            onTap: () {
              ascending.value = !ascending.value;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ),
  );
}

String _sortLabel(TransferSort s) => switch (s) {
      TransferSort.created => '创建时间',
      TransferSort.name => '名称',
      TransferSort.size => '大小',
      TransferSort.progress => '进度',
      TransferSort.status => '状态',
    };
