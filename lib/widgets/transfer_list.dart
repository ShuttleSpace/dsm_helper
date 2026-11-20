import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/services/transfer_download.dart';
import 'package:garden/services/transfer_upload.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:garden/widgets/bottom_option_sheet.dart';
import 'package:garden/widgets/bottom_sheet_card.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_card.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

enum TransferSort { created, name, size, progress, status }

TransferType? transferTabType(int tab) => switch (tab) {
      1 => TransferType.download,
      2 => TransferType.upload,
      _ => null,
    };

TransferState? transferTabState(int tab) => switch (tab) {
      3 => TransferState.error,
      4 => TransferState.done,
      _ => null,
    };

/// 当前 tab 的任务过滤 + 排序；搜索、排序状态由页面持有，切 tab 不重置。
List<TransferTask> filterTransferTasks({
  required int tab,
  required String query,
  required TransferSort sort,
  required bool ascending,
  Iterable<TransferTask>? source,
  TransferType? type,
  TransferState? state,
}) {
  type ??= transferTabType(tab);
  state ??= transferTabState(tab);
  final keyword = query.trim().toLowerCase();
  final tasks = (source ?? transferStore.tasks.value).where((t) {
    if (type != null && t.type != type) return false;
    if (state != null && t.state != state) return false;
    if (keyword.isEmpty) return true;
    return t.remotePath.toLowerCase().contains(keyword) ||
        t.localPath.toLowerCase().contains(keyword);
  }).toList();

  int compare(TransferTask a, TransferTask b) => switch (sort) {
        TransferSort.created =>
          (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        TransferSort.name => _nameOf(a).compareTo(_nameOf(b)),
        TransferSort.size => a.totalBytes.compareTo(b.totalBytes),
        TransferSort.progress => _progressOf(a).compareTo(_progressOf(b)),
        TransferSort.status => a.state.index.compareTo(b.state.index),
      };
  tasks.sort((a, b) {
    final result = compare(a, b);
    return ascending ? result : -result;
  });
  return tasks;
}

String _nameOf(TransferTask t) => t.remotePath.split('/').last;

int _progressOf(TransferTask t) => t.state == TransferState.done
    ? 100
    : t.totalBytes > 0
        ? (t.transferredBytes / t.totalBytes * 100).round()
        : 0;

String _formatEta(int seconds) {
  if (seconds >= 3600) {
    return '${seconds ~/ 3600}时${seconds % 3600 ~/ 60}分';
  }
  if (seconds >= 60) return '${seconds ~/ 60}分${seconds % 60}秒';
  return '$seconds秒';
}

String _formatSpeed(double bytesPerSecond) =>
    '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';

String _dateKey(DateTime? time) {
  if (time == null) return '更早';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(time.year, time.month, time.day);
  if (date == today) return '今天';
  if (date == today.subtract(const Duration(days: 1))) return '昨天';
  if (date.isBefore(today.subtract(const Duration(days: 30)))) return '更早';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

/// 客户端传输队列（下载/上传）列表，订阅 [transferStore.tasks]。
/// [type] / [state] 为空时不过滤；用于「传输」页的 5 个分类 tab。
class TransferList extends HookWidget {
  final TransferType? type;
  final TransferState? state;
  final String emptyText;
  final int tab;
  final String query;
  final TransferSort sort;
  final bool ascending;
  final bool groupByDate;
  final bool multiSelect;
  final Set<String> selectedIds;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onLongPress;

  const TransferList({
    super.key,
    this.type,
    this.state,
    this.emptyText = "暂无传输任务",
    this.tab = 0,
    this.query = '',
    this.sort = TransferSort.created,
    this.ascending = false,
    this.groupByDate = false,
    this.multiSelect = false,
    this.selectedIds = const {},
    this.onSelect,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    useExistingSignal(transferStore.tasks).watch(context);
    final filtered = filterTransferTasks(
      tab: tab,
      type: type,
      state: state,
      query: query,
      sort: sort,
      ascending: ascending,
    );
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: AppTheme.of(context).placeholderColor),
        ),
      );
    }

    final showBoundary = filtered.any((t) => t.type == TransferType.upload);
    final rows = <Object>[
      if (showBoundary) _boundaryKey,
      ..._rowsWithGroups(filtered),
    ];
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row == _boundaryKey) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              '中断后需重新上传',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          );
        }
        if (row is _GroupKey) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              row.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.of(context).titleColor,
              ),
            ),
          );
        }
        return _buildRow(context, row as TransferTask);
      },
    );
  }

  static const _boundaryKey = 'boundary';

  List<Object> _rowsWithGroups(List<TransferTask> tasks) {
    if (!groupByDate || sort == TransferSort.name) return tasks;
    final groups = <String, List<TransferTask>>{};
    final groupTime = <String, DateTime>{};
    final order = <String>[];
    for (final t in tasks) {
      final key = _dateKey(t.createdAt);
      if (groups.putIfAbsent(key, () => []).isEmpty) order.add(key);
      groups[key]!.add(t);
      final time = t.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (!groupTime.containsKey(key) || time.isAfter(groupTime[key]!)) {
        groupTime[key] = time;
      }
    }
    if (sort == TransferSort.created && !ascending) {
      order.sort((a, b) => groupTime[b]!.compareTo(groupTime[a]!));
    }
    return [
      for (final key in order) ...[
        _GroupKey(key),
        ...groups[key]!,
      ],
    ];
  }

  Widget _buildRow(BuildContext context, TransferTask t) {
    final theme = AppTheme.of(context);
    final name = _nameOf(t);
    final pct = _progressOf(t);
    final selected = selectedIds.contains(t.id);
    final stateText = _stateText(t.state);
    final stateColor = _stateColor(context, t.state);

    return NeuCard(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: () {
        if (multiSelect) {
          onSelect?.call(t.id);
        } else {
          _showActions(context, t);
        }
      },
      onLongPress: () {
        if (multiSelect || onLongPress == null) {
          onSelect?.call(t.id);
        } else {
          onLongPress!.call(t.id);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (multiSelect)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected
                        ? AppColors.infoOf(context)
                        : theme.placeholderColor,
                  ),
                ),
              Icon(
                t.type == TransferType.download
                    ? Icons.download
                    : Icons.upload,
                size: 20,
                color: AppColors.infoOf(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 14, color: theme.titleColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Label(stateText, stateColor, fill: t.state == TransferState.active),
            ],
          ),
          if (t.type == TransferType.download && t.state != TransferState.done) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${t.transferredBytes.formatSize()} / ${t.totalBytes.formatSize()}',
                  style: TextStyle(fontSize: 12, color: theme.placeholderColor),
                ),
                const Spacer(),
                Text(
                  '速度 ${_speedText(t)}',
                  style: TextStyle(fontSize: 12, color: theme.placeholderColor),
                ),
                const SizedBox(width: 10),
                Text(
                  '剩余 ${_etaText(t)}',
                  style: TextStyle(fontSize: 12, color: theme.placeholderColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FAProgressBar(
              backgroundColor: Colors.transparent,
              changeColorValue: 100,
              changeProgressColor: AppColors.successOf(context),
              progressColor: AppColors.infoOf(context),
              size: 20,
              currentValue: pct,
              displayText: '%',
            ),
          ],
          if (t.errorMessage != null && t.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              t.statusCode != null
                  ? '失败 ${t.statusCode}: ${t.errorMessage}'
                  : '失败 ${t.errorMessage}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.errorOf(context)),
            ),
          ],
        ],
      ),
    );
  }

  void _showActions(BuildContext context, TransferTask t) {
    final options = <BottomOption>[
      if (t.state == TransferState.active)
        BottomOption(title: '暂停', onPressed: () => _pause(t)),
      if (t.state == TransferState.paused || t.state == TransferState.error)
        BottomOption(title: '继续', onPressed: () => _resume(t)),
      if (t.state == TransferState.error)
        BottomOption(title: '重试', onPressed: () => _retry(t)),
      if (t.state != TransferState.done && t.state != TransferState.canceled)
        BottomOption(
          title: '取消任务',
          onPressed: () => _confirm(context, t, '取消', (task) => _cancel(task)),
        ),
      BottomOption(
        title: '移除',
        onPressed: () => _confirm(context, t, '移除', (task) => _remove(task.id)),
      ),
      BottomOption(
        title: '详情',
        onPressed: () => showTransferTaskDetail(context, t),
      ),
    ];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => BottomOptionSheet(
        title: '任务操作',
        options: options,
      ),
    );
  }

  void _confirm(
    BuildContext context,
    TransferTask t,
    String label,
    Future<void> Function(TransferTask) action,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => BottomConfirmSheet(
        title: '$label任务',
        content: '1 项',
        confirmText: label,
        cancelText: '返回',
        onConfirm: () async {
          await action(t);
        },
      ),
    );
  }

  static String _stateText(TransferState s) => switch (s) {
        TransferState.queued => '排队',
        TransferState.active => '进行中',
        TransferState.paused => '已暂停',
        TransferState.done => '已完成',
        TransferState.error => '失败',
        TransferState.canceled => '已取消',
      };

  static Color _stateColor(BuildContext context, TransferState s) => switch (s) {
        TransferState.queued => AppTheme.of(context).placeholderColor ?? Colors.grey,
        TransferState.active => AppColors.infoOf(context),
        TransferState.paused => AppColors.warningOf(context),
        TransferState.done => AppColors.successOf(context),
        TransferState.error => AppColors.errorOf(context),
        TransferState.canceled => AppTheme.of(context).placeholderColor ?? Colors.grey,
      };

  static String _speedText(TransferTask t) => t.speedBytesPerSecond != null &&
          t.speedBytesPerSecond! > 0
      ? _formatSpeed(t.speedBytesPerSecond!)
      : '--';

  static String _etaText(TransferTask t) =>
      t.etaSeconds != null && t.etaSeconds! >= 0
          ? _formatEta(t.etaSeconds!)
          : '--';

  Future<void> _pause(TransferTask t) async {
    final ok = await transferStore.pauseTask(t.id);
    UiUtil.toast(ok ? '已暂停任务' : '暂停失败');
  }

  Future<void> _resume(TransferTask t) async {
    final ok = await transferStore.resumeTask(t.id);
    UiUtil.toast(ok ? '已继续任务' : '继续失败，请重新添加任务');
  }

  Future<void> _cancel(TransferTask t) async {
    final ok = await transferStore.cancelTask(t.id);
    UiUtil.toast(ok ? '已取消任务' : '取消失败');
  }

  Future<bool> _remove(String id) async {
    transferStore.remove(id);
    await FileDownloader().database.deleteRecordWithId(id);
    UiUtil.toast('已移除');
    return true;
  }

  /// 重试必须先清掉旧记录，否则同一次失败会留下重复任务。
  Future<void> _retry(TransferTask t) async {
    final String newId;
    try {
      if (t.type == TransferType.upload) {
        final remoteDir = t.remotePath.substring(
          0,
          t.remotePath.lastIndexOf('/'),
        );
        newId = await enqueueFileUpload(
          localPath: t.localPath,
          remoteDir: remoteDir,
        );
      } else {
        final destDir = await downloadTargetDir();
        newId = await enqueueFileDownload(
          remotePath: t.remotePath,
          destDir: destDir,
        );
      }
    } catch (_) {
      UiUtil.toast('重试失败，请检查连接');
      return;
    }
    await FileDownloader().cancelTaskWithId(t.id);
    await FileDownloader().database.deleteRecordWithId(t.id);
    transferStore.remove(t.id);
    transferStore.add(TransferTask(
      id: newId,
      type: t.type,
      localPath: t.localPath,
      remotePath: t.remotePath,
      state: TransferState.active,
      createdAt: t.createdAt,
    ));
    UiUtil.toast('已重新加入队列');
  }
}

class _GroupKey {
  const _GroupKey(this.label);
  final String label;
}

/// 传输任务详情面板：只展示可读信息，不展示响应体或临时分片路径。
void showTransferTaskDetail(BuildContext context, TransferTask task) {
  final theme = AppTheme.of(context);
  Widget row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: theme.placeholderColor)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 13, color: theme.titleColor),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  showCupertinoModalPopup(
    context: context,
    builder: (context) => BottomSheetCard(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nameOf(task),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: theme.titleColor),
            ),
            const SizedBox(height: 16),
            row('状态', TransferList._stateText(task.state)),
            row('大小', task.totalBytes.formatSize()),
            row('已传', '${task.transferredBytes.formatSize()} · ${_progressOf(task)}%'),
            row('速度', TransferList._speedText(task)),
            row('剩余', TransferList._etaText(task)),
            if (task.errorMessage != null && task.errorMessage!.isNotEmpty)
              row('原因', task.statusCode != null
                  ? '${task.statusCode}: ${task.errorMessage}'
                  : task.errorMessage!),
            row('创建', task.createdAt?.toLocal().toString().substring(0, 19) ?? '--'),
            row('更新', task.updatedAt?.toLocal().toString().substring(0, 19) ?? '--'),
            row('远程', task.remotePath),
            row('本地', task.localPath),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    ),
  );
}
