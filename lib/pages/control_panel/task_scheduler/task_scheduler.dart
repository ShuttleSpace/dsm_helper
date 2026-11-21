import 'dart:convert';
import 'package:garden/pages/control_panel/task_scheduler/task_record.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class TaskScheduler extends HookWidget {
  const TaskScheduler({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final tasks = useSignal<List>([]);

    Future<void> getData() async {
      try {
        final data = await dsmControlPanelPost({
          "api": "SYNO.Core.TaskScheduler",
          "offset": 0,
          "limit": -1,
          "sort_by": "next_trigger_time",
          "sort_direction": "DESC",
          "version": 1,
          "method": "list",
        });
        tasks.value = data['tasks'] ?? [];
        loading.value = false;
      } catch (e) {
        UiUtil.toast("加载失败");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      }
    }

    // Task entries are plain maps; mutating them in place needs an explicit
    // signal write to rebuild the list (the old code relied on setState).
    void refreshTasks() {
      tasks.value = List.of(tasks.value);
    }

    Widget buildTaskItem(task) {
    task['running'] = task['running'] ?? false;
    task['set'] = task['set'] ?? false;
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin:
          const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Label(task['owner'], Colors.lightBlueAccent),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          task['name'],
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(task['app_name'] ?? "用户定义的脚本"),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "下次：${task['type'] == 'script' ? task['next_trigger_time'] : (task['next_trigger_time'] == 'bootup' ? '开机' : task['next_trigger_time'] == 'shutdown' ? '关机' : task['next_trigger_time'])} ",
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    task['action'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    task['set'] = true;
                    refreshTasks();
                    try {
                      await dsmControlPanelPost({
                        "api": "SYNO.Core.TaskScheduler",
                        "version": 1,
                        "method": "set_enable",
                        "status": jsonEncode([
                          {"id": task['id'], "enable": !task['enable']}
                        ]),
                      });
                      task['enable'] = !task['enable'];
                      refreshTasks();
                    } catch (e) {
                      final code = e is DSMException ? e.code : -1;
                      UiUtil.toast("操作失败，code：$code");
                    } finally {
                      task['set'] = false;
                      refreshTasks();
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: task['set']
                            ? const CupertinoActivityIndicator()
                            : task['enable']
                                ? const Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color: AppColors.primaryAction,
                                  )
                                : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                if (task['type'] == 'script')
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.of(context).push(CupertinoPageRoute(
                          builder: (context) {
                            return TaskRecord(task['id']);
                          },
                          settings: const RouteSettings(name: "task_record")));
                    },
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        CupertinoIcons.list_bullet,
                        color: AppColors.primaryAction,
                        size: 16,
                      ),
                    ),
                  ),
                const SizedBox(
                  height: 5,
                ),
                OutlinedButton(
                  onPressed: () async {
                    if (task['running']) {
                      return;
                    }
                    task['running'] = true;
                    refreshTasks();
                    try {
                      if (task['type'] == 'script') {
                        await dsmCoreTaskSchedulerRunBatch([task['id'] as int]);
                      } else if (task['type'] == 'event_script') {
                        await dsmControlPanelPost({
                          "api": "SYNO.Core.EventScheduler",
                          "version": 1,
                          "method": "run",
                          "task_name": task['name'],
                        });
                      } else {
                        UiUtil.toast("暂不支持此类型任务");
                        return;
                      }
                      UiUtil.toast("任务计划执行成功");
                    } catch (e) {
                      final code = e is DSMException ? e.code : -1;
                      UiUtil.toast("任务计划执行失败，code：$code");
                    } finally {
                      task['running'] = false;
                      refreshTasks();
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
          ],
        ),
      ),
    );
  }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("任务计划"),
      ),
      body: loading.value
          ? Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: .7),
              child: const Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, i) {
                return buildTaskItem(tasks.value[i]);
              },
              itemCount: tasks.value.length,
            ),
    );
  }
}
