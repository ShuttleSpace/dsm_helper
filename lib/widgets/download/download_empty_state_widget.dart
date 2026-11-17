import 'package:flutter/material.dart';
import 'package:garden/theme/app_theme.dart';

/// 下载页面空状态显示组件
class DownloadEmptyStateWidget extends StatelessWidget {
  final String text;
  const DownloadEmptyStateWidget({super.key, this.text = "暂无下载任务"});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(color: AppTheme.of(context).placeholderColor),
          ),
          const SizedBox(
            height: 5,
          ),
          const Text(
            "可在[文件]中点击文件右侧 > 将文件下载到手机",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
