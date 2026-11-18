
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/control_panel/task_scheduler/task_scheduler.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:garden/widgets/dashboard/dashboard_card_parts.dart';

class DashboardTaskSchedulerCard extends HookWidget {
  const DashboardTaskSchedulerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final schedulerTasks = useListSignal([]);
    final error = useSignal('');

    fetchData() {
      dsmCoreTaskSchedulerList(
        sortBy: 'next_trigger_time',
        sortDirection: 'ASC',
      ).then((res) {
        schedulerTasks.value = res['tasks'] as List;
        debugPrint("哇咔咔🎊🎊🎊");
      }).catchError((e) {
        error.value = e.toString();
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return const TaskScheduler();
        }));
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/task.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "计划任务",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const DashboardCardItemCollapse("TaskScheduler")
                  ],
                ),
              ),
              Builder(builder: (context) {
                if (schedulerTasks.watch(context).isEmpty) {
                  return Text.rich(TextSpan(
                      text: error.isNotEmpty ? error.value : '暂无任务',
                      children: [
                        TextSpan(
                            text: '\t\t点击重试', style: dashboardRetryTextStyle(context)),
                      ]));
                }
                if (context.isCardItemCollapsed('TaskScheduler')) {
                  return Flexible(
                      child: Column(
                    children: schedulerTasks
                        .map((e) => _DashboardTashSchedulerItem(e))
                        .toList(),
                  ));
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTashSchedulerItem extends StatelessWidget {
  _DashboardTashSchedulerItem(this.task);
  final Map task;
  final running = signal(false);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Flexible(
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
                if (running.value) {
                  return;
                }
                running.value = true;
                dsmCoreTaskSchedulerRun(task['id']).then((res) {
                  UiUtil.toast('任务计划执行成功');
                }).catchError((e) {
                  UiUtil.toast('任务计划执行失败，code：${e.toString()}');
                });
              },
              child: SizedBox(
                width: 20,
                height: 20,
                child: running.watch(context)
                    ? const CupertinoActivityIndicator()
                    : const Icon(
                        CupertinoIcons.play_arrow_solid,
                        color: Color(0xffff9813),
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

