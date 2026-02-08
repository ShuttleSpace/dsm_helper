import 'package:background_downloader/background_downloader.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/download/download_action_menu_widget.dart';
import 'package:garden/widgets/download/download_status_widget.dart';
import 'package:garden/widgets/file_icon.dart';
// ignore: library_prefixes
import 'package:path/path.dart' as Path;
import 'package:signals_flutter/signals_flutter.dart';

/// 下载任务列表项组件
class DownloadTaskItemWidget extends StatelessWidget {
  final DownloadInfo info;
  final Signal<bool> multiSelect;
  final Signal<List<DownloadInfo>> selectedTasks;
  final Signal<List<DownloadInfo>> tasks;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const DownloadTaskItemWidget({
    super.key,
    required this.info,
    required this.multiSelect,
    required this.selectedTasks,
    required this.tasks,
    required this.onLongPress,
    required this.onTap,
    required this.onRetry,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    FileTypeEnum fileType = FileTypeUtil.toFileTypeEnum(
        FileTypeUtil.getFileType(info.task.filename));

    return Padding(
      padding:
          const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 20, right: 20),
      child: Watch((context) => OutlinedButton(
            onLongPress: () {
              UiUtil.vibrate(FeedbackType.light);
              onLongPress();
            },
            onPressed: () {
              if (multiSelect.value) {
                if (selectedTasks.value.contains(info)) {
                  final currentTasks = [...selectedTasks.value];
                  currentTasks.remove(info);
                  selectedTasks.value = currentTasks;
                } else {
                  final currentTasks = [...selectedTasks.value];
                  currentTasks.add(info);
                  selectedTasks.value = currentTasks;
                }
              } else {
                onTap();
              }
            },
            child: Row(
              children: [
                const SizedBox(width: 20),
                _buildFileIcon(context, fileType),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTaskInfo(context),
                ),
                const SizedBox(width: 10),
                _buildTrailing(context),
                const SizedBox(width: 20),
              ],
            ),
          )),
    );
  }

  Widget _buildFileIcon(BuildContext context, FileTypeEnum fileType) {
    return Hero(
      tag: Path.join(info.task.directory, info.task.filename),
      child: FileIcon(
        fileType,
        thumb:
            fileType == FileTypeEnum.image && info.status == TaskStatus.complete
                ? Path.join(info.task.directory, info.task.filename)
                : '',
        network: false,
      ),
    );
  }

  Widget _buildTaskInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.task.filename,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 5),
        Text(
          DateTime.fromMillisecondsSinceEpoch(
                  info.task.creationTime.secondsSinceEpoch)
              .format("Y/m/d H:i:s"),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        const SizedBox(height: 5),
        DownloadStatusWidget(
          status: info.status ?? TaskStatus.notFound,
          progress: info.progress ?? 0,
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Watch((context) => multiSelect.value
        ? _buildSelectionIndicator()
        : _buildActionMenuButton(context));
  }

  Widget _buildSelectionIndicator() {
    return Watch((context) => Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            width: 20,
            height: 20,
            child: selectedTasks.value.contains(info)
                ? Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Container(),
          ),
        ));
  }

  Widget _buildActionMenuButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => DownloadActionMenuWidget(
            task: info.task,
            status: info.status ?? TaskStatus.notFound,
            onRetry: onRetry,
            onPause: onPause,
            onResume: onResume,
            onDelete: onDelete,
          ),
        );
      },
      child: const Icon(CupertinoIcons.right_chevron, size: 18),
    );
  }
}
