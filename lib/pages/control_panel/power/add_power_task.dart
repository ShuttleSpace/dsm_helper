import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class AddPowerTask extends HookWidget {
  final String title;
  final Map? task;
  const AddPowerTask(this.title, {super.key, this.task});

  @override
  Widget build(BuildContext context) {
    // An existing task map is edited in place and shared with the page that
    // opened this one (same as the original initState assignment).
    final taskValue = useSignal<Map>(task ??
        {
          "enabled": true,
          "hour": 0,
          "min": 0,
          "weekdays": "0,1,2,3,4,5,6",
          "type": "power_on",
        });
    final weekdays =
        useSignal<List<String>>(["0", "1", "2", "3", "4", "5", "6"]);

    // Weekday toggles mutate the list in place; writing a new list keeps the
    // signal notifying (the old code relied on setState).
    void toggleWeekday(String day) {
      final list = List.of(weekdays.value);
      if (list.contains(day)) {
        list.remove(day);
      } else {
        list.add(day);
      }
      list.sort((a, b) {
        return a.compareTo(b);
      });
      weekdays.value = list;
      // The map instance is shared with the page that opened this one, so it
      // is mutated in place (the original code did the same) and the signal is
      // notified explicitly to rebuild.
      taskValue.value['weekdays'] = list.join(",");
      taskValue.notifyListeners();
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "类型",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            taskValue.value['type'] = "power_on";
                            taskValue.notifyListeners();
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("开机"),
                                  const Spacer(),
                                  if (taskValue.value['type'] == "power_on")
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            taskValue.value['type'] = "power_off";
                            taskValue.notifyListeners();
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("关机"),
                                  const Spacer(),
                                  if (taskValue.value['type'] == "power_off")
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "星期",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            toggleWeekday("0");
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("日"),
                                  const Spacer(),
                                  if (weekdays.value.contains("0"))
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            toggleWeekday("1");
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("一"),
                                  const Spacer(),
                                  if (weekdays.value.contains("1"))
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            toggleWeekday("2");
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("二"),
                                  const Spacer(),
                                  if (weekdays.value.contains("2"))
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            toggleWeekday("3");
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("三"),
                                  const Spacer(),
                                  if (weekdays.value.contains("3"))
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            toggleWeekday("4");
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("四"),
                                  const Spacer(),
                                  if (weekdays.value.contains("4"))
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            toggleWeekday("5");
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("五"),
                                  const Spacer(),
                                  if (weekdays.value.contains("5"))
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            toggleWeekday("6");
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Text("六"),
                                  const Spacer(),
                                  if (weekdays.value.contains("6"))
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(flex: 1, child: Container()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "时间",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            DatePicker.showTimePicker(
                              context,
                              currentTime: DateTime(2021, 01, 01,
                                  taskValue.value['hour'], taskValue.value['min']),
                              showSecondsColumn: false,
                              onConfirm: (time) {
                                taskValue.value['hour'] = time.hour;
                                taskValue.value['min'] = time.minute;
                                taskValue.notifyListeners();
                              },
                              locale: LocaleType.zh,
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  Text(
                                      "${taskValue.value['hour'].toString().padLeft(2, "0")}:${taskValue.value['min'].toString().padLeft(2, "0")}"),
                                  const Spacer(),
                                  const Icon(
                                    CupertinoIcons.right_chevron,
                                    color: AppColors.primaryAction,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(taskValue.value);
            },
            child: const Text(
              ' 确定 ',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
