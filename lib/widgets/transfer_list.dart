import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.filestation.transfer_contract.dart';
import 'package:garden/extensions/string.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:garden/services/transfer_download.dart';
import 'package:garden/services/transfer_upload.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/download/download_empty_state_widget.dart';

/// 客户端传输队列（下载/上传）列表，订阅 [transferStore.tasks]。
/// [type] / [state] 为空时不过滤；用于「传输」页的 5 个分类 tab。
class TransferList extends StatelessWidget {
  final TransferType? type;
  final TransferState? state;
  final String emptyText;
  const TransferList({
    super.key,
    this.type,
    this.state,
    this.emptyText = "暂无传输任务",
  });

  @override
  Widget build(BuildContext context) {
    final tasks = transferStore.tasks.watch(context);
    final filtered = tasks.where((t) {
      if (type != null && t.type != type) return false;
      if (state != null && t.state != state) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) {
      return DownloadEmptyStateWidget(text: emptyText);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 能力边界必须随上传任务可见，禁止无提示假续传。
        if (filtered.any((t) => t.type == TransferType.upload))
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              uploadResumeBoundaryText,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ...filtered.map((t) => _buildRow(context, t)),
      ],
    );
  }

  Widget _buildRow(BuildContext context, TransferTask t) {
    final name = t.remotePath.split('/').last;
    final pct =
        t.totalBytes > 0 ? (t.transferredBytes / t.totalBytes * 100).round() : 0;
    final active = t.state == TransferState.active;

    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (active)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('后台进行中',
                        style: TextStyle(fontSize: 11, color: Colors.blue)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FAProgressBar(
              backgroundColor: Colors.transparent,
              changeColorValue: 100,
              changeProgressColor: Colors.green,
              progressColor: Colors.blue,
              size: 20,
              currentValue: pct,
              displayText: '%',
            ),
            const SizedBox(height: 8),
            _buildControls(context, t),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, TransferTask t) {
    final theme = AppTheme.of(context);
    Widget btn(String label, VoidCallback onTap, {Color? color}) => TextButton(
          onPressed: onTap,
          child: Text(label, style: TextStyle(fontSize: 12, color: color)),
        );

    switch (t.state) {
      case TransferState.active:
        return Row(
          children: [
            btn('暂停', () => transferStore.pauseTask(t.id), color: theme.placeholderColor),
            btn('取消', () => transferStore.cancelTask(t.id), color: Colors.red),
          ],
        );
      case TransferState.paused:
        return Row(
          children: [
            btn('继续', () => transferStore.resumeTask(t.id), color: Colors.blue),
            btn('取消', () => transferStore.cancelTask(t.id), color: Colors.red),
          ],
        );
      case TransferState.error:
        return Row(
          children: [
            btn('重试', () => _retry(t), color: Colors.blue),
            btn('取消', () => transferStore.cancelTask(t.id), color: Colors.red),
          ],
        );
      case TransferState.done:
      case TransferState.canceled:
      case TransferState.queued:
        return Row(
          children: [
            btn('移除', () => _remove(t.id), color: theme.placeholderColor),
          ],
        );
    }
  }

  Future<void> _retry(TransferTask t) async {
    transferStore.setState(t.id, TransferState.active);
    if (t.type == TransferType.upload) {
      final remoteDir = t.remotePath.substring(
        0,
        t.remotePath.lastIndexOf('/'),
      );
      await enqueueFileUpload(
        localPath: t.localPath,
        remoteDir: remoteDir,
      );
    } else {
      final destDir = await downloadTargetDir();
      await enqueueFileDownload(
        remotePath: t.remotePath,
        destDir: destDir,
      );
    }
  }

  void _remove(String id) {
    transferStore.remove(id);
  }
}
