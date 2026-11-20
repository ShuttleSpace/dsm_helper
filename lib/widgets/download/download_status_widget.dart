import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

/// 显示下载状态的组件
class DownloadStatusWidget extends StatelessWidget {
  final TaskStatus status;
  final int progress;

  const DownloadStatusWidget({
    super.key,
    required this.status,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (status == TaskStatus.complete) {
      return _buildStatusCard(context, "下载完成");
    } else if (status == TaskStatus.failed) {
      return _buildStatusCard(context, "下载失败");
    } else if (status == TaskStatus.canceled) {
      return _buildStatusCard(context, "取消下载");
    } else if (status == TaskStatus.paused) {
      return _buildStatusCard(context, "暂停下载");
    } else if (status == TaskStatus.running) {
      return _buildProgress(context, progress);
    } else if (status == TaskStatus.enqueued) {
      return _buildStatusCard(context, "等待下载");
    } else {
      return Container();
    }
  }

  Widget _buildStatusCard(BuildContext context, String text) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 3),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, color: AppColors.primaryOf(context)),
        ),
      ),
    );
  }

  /// 下载中显示进度条 + 百分比（progress 为 0~100）。
  Widget _buildProgress(BuildContext context, int progress) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress / 100.0,
            minHeight: 4,
          ),
          const SizedBox(height: 2),
          Text(
            '$progress%',
            style: TextStyle(fontSize: 10, color: AppColors.primaryOf(context)),
          ),
        ],
      ),
    );
  }
}
