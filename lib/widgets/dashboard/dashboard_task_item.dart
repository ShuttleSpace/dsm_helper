import 'package:flutter/cupertino.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/http_util.dart';

/// Dashboard 计划任务列表项
class DashboardTaskItem extends StatefulWidget {
  final Map task;

  const DashboardTaskItem({
    super.key,
    required this.task,
  });

  @override
  State<DashboardTaskItem> createState() => _DashboardTaskItemState();
}

class _DashboardTaskItemState extends State<DashboardTaskItem> {
  @override
  Widget build(BuildContext context) {
    Map task = widget.task;
    task['running'] = task['running'] ?? false;
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${task['name']}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              "${task['next_trigger_time']}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              width: 5,
            ),
            OutlinedButton(
              onPressed: () async {
                if (task['running']) {
                  return;
                }
                setState(() {
                  task['running'] = true;
                });
                var res = await DsmApi.taskRun([task['id']]);
                setState(() {
                  task['running'] = false;
                });
                if (res['success']) {
                  UiUtil.toast("任务计划执行成功");
                } else {
                  UiUtil.toast("任务计划执行失败，code：${res['error']['code']}");
                }
              },
              child: SizedBox(
                width: 20,
                height: 20,
                child: task['running']
                    ? const CupertinoActivityIndicator()
                    : const Icon(
                        CupertinoIcons.play_arrow_solid,
                        color: AppColors.primaryAction,
                        size: 16,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
