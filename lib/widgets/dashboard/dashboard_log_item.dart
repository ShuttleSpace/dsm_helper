import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// Dashboard 日志列表项
class DashboardLogItem extends StatelessWidget {
  final Map log;

  const DashboardLogItem({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          maxLines: 3,
          "${log['msg']}",
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Dashboard 文件日志列表项
class DashboardFileLogItem extends StatelessWidget {
  final Map log;

  const DashboardFileLogItem({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          children: [
            Icon(log['cmd'] == "delete"
                ? Icons.delete
                : log['cmd'] == "copy"
                    ? Icons.copy
                    : log['cmd'] == "edit"
                        ? Icons.edit
                        : log['cmd'] == "move"
                            ? Icons.drive_file_move_outline
                            : log['cmd'] == "download"
                                ? Icons.download_outlined
                                : log['cmd'] == "upload"
                                    ? Icons.upload_outlined
                                    : log['cmd'] == "rename"
                                        ? Icons.drive_file_rename_outline
                                        : Icons.code),
            Expanded(
              child: Text(
                "${log['descr']}",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
