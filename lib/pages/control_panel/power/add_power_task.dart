import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class AddPowerTask extends StatefulWidget {
  final String title;
  final Map? task;
  const AddPowerTask(this.title, {super.key, this.task});
  @override
  AddPowerTaskState createState() => AddPowerTaskState();
}

class AddPowerTaskState extends State<AddPowerTask> {
  Map task = {
    "enabled": true,
    "hour": 0,
    "min": 0,
    "weekdays": "0,1,2,3,4,5,6",
    "type": "power_on",
  };
  List<String> weekdays = ["0", "1", "2", "3", "4", "5", "6"];

  @override
  void initState() {
    if (widget.task != null) {
      setState(() {
        task = widget.task!;
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(widget.title),
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
                            setState(() {
                              task['type'] = "power_on";
                            });
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
                                  if (task['type'] == "power_on")
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
                            setState(() {
                              task['type'] = "power_off";
                            });
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
                                  if (task['type'] == "power_off")
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
                            setState(() {
                              if (weekdays.contains("0")) {
                                weekdays.remove("0");
                              } else {
                                weekdays.add("0");
                              }
                              weekdays.sort((a, b) {
                                return a.compareTo(b);
                              });
                              task['weekdays'] = weekdays.join(",");
                            });
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
                                  if (weekdays.contains("0"))
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
                            setState(() {
                              if (weekdays.contains("1")) {
                                weekdays.remove("1");
                              } else {
                                weekdays.add("1");
                              }
                              weekdays.sort((a, b) {
                                return a.compareTo(b);
                              });
                              task['weekdays'] = weekdays.join(",");
                            });
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
                                  if (weekdays.contains("1"))
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
                            setState(() {
                              if (weekdays.contains("2")) {
                                weekdays.remove("2");
                              } else {
                                weekdays.add("2");
                              }
                              weekdays.sort((a, b) {
                                return a.compareTo(b);
                              });
                              task['weekdays'] = weekdays.join(",");
                            });
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
                                  if (weekdays.contains("2"))
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
                            setState(() {
                              if (weekdays.contains("3")) {
                                weekdays.remove("3");
                              } else {
                                weekdays.add("3");
                              }
                              weekdays.sort((a, b) {
                                return a.compareTo(b);
                              });
                              task['weekdays'] = weekdays.join(",");
                            });
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
                                  if (weekdays.contains("3"))
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
                            setState(() {
                              if (weekdays.contains("4")) {
                                weekdays.remove("4");
                              } else {
                                weekdays.add("4");
                              }
                              weekdays.sort((a, b) {
                                return a.compareTo(b);
                              });
                              task['weekdays'] = weekdays.join(",");
                            });
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
                                  if (weekdays.contains("4"))
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
                            setState(() {
                              if (weekdays.contains("5")) {
                                weekdays.remove("5");
                              } else {
                                weekdays.add("5");
                              }
                              weekdays.sort((a, b) {
                                return a.compareTo(b);
                              });
                              task['weekdays'] = weekdays.join(",");
                            });
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
                                  if (weekdays.contains("5"))
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
                            setState(() {
                              if (weekdays.contains("6")) {
                                weekdays.remove("6");
                              } else {
                                weekdays.add("6");
                              }
                              weekdays.sort((a, b) {
                                return a.compareTo(b);
                              });
                              task['weekdays'] = weekdays.join(",");
                            });
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
                                  if (weekdays.contains("6"))
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
                              currentTime: DateTime(
                                  2021, 01, 01, task['hour'], task['min']),
                              showSecondsColumn: false,
                              onConfirm: (time) {
                                setState(() {
                                  task['hour'] = time.hour;
                                  task['min'] = time.minute;
                                });
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
                                      "${task['hour'].toString().padLeft(2, "0")}:${task['min'].toString().padLeft(2, "0")}"),
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
              Navigator.of(context).pop(task);
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
