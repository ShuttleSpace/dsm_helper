import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/control_panel/task_scheduler/task_record.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/constants/app_constants.dart';

class TaskScheduler extends StatefulWidget {
  const TaskScheduler({super.key});

  @override
  TaskSchedulerState createState() => TaskSchedulerState();
}

class TaskSchedulerState extends State<TaskScheduler> {
  bool loading = true;
  List tasks = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await dsmCoreTaskSchedulerList();
    if (res['success']) {
      setState(() {
        loading = false;
        tasks = res['data']['tasks'];
      });
    } else {
      UiUtil.toast("加载失败");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildTaskItem(task) {
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
                    setState(() {
                      task['set'] = true;
                    });
                    var res = await dsmCoreTaskSchedulerSetEnable(
                        task['id'], !task['enable']);
                    setState(() {
                      task['set'] = false;
                    });
                    if (res['success']) {
                      setState(() {
                        task['enable'] = !task['enable'];
                      });
                    } else {
                      UiUtil.toast("操作失败，code：${res['error']['code']}");
                    }
                  },
                  child: Card(
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: task['set']
                            ? const CupertinoActivityIndicator()
                            : task['enable']
                                ? Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        CupertinoIcons.list_bullet,
                        color: Theme.of(context).colorScheme.primary,
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
                    setState(() {
                      task['running'] = true;
                    });
                    Map<dynamic, dynamic> res;
                    if (task['type'] == 'script') {
                      res = await dsmCoreTaskSchedulerRun(task['id']);
                    } else if (task['type'] == 'event_script') {
                      res = await DsmApi.eventRun([task['name']]);
                    } else {
                      UiUtil.toast("暂不支持此类型任务");
                      return;
                    }
                  },
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: task['running']
                        ? const CupertinoActivityIndicator()
                        : Icon(
                            CupertinoIcons.play_arrow_solid,
                            color: Theme.of(context).colorScheme.primary,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("任务计划"),
      ),
      body: loading
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
                return _buildTaskItem(tasks[i]);
              },
              itemCount: tasks.length,
            ),
    );
  }
}
