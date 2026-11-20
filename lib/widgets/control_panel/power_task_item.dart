import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/label.dart';

class PowerTaskItem extends StatelessWidget {
  final Map task;
  final Function(Map) onEnabledChanged;
  final Function(Map) onRemove;
  final Function(Map) onEdit;

  const PowerTaskItem({
    super.key,
    required this.task,
    required this.onEnabledChanged,
    required this.onRemove,
    required this.onEdit,
  });

  Map get weekday => {
        "0": "周日",
        "1": "周一",
        "2": "周二",
        "3": "周三",
        "4": "周四",
        "5": "周五",
        "6": "周六",
      };

  String _formatWeekdays(String weekdays) {
    if (weekdays == "0,1,2,3,4,5,6") {
      return "每天";
    } else if (weekdays == "1,2,3,4,5") {
      return "平日";
    } else if (weekdays == "0,6") {
      return "假日";
    } else {
      List days = weekdays.split(",");
      return days.map((e) => weekday[e]).join(",");
    }
  }

  @override
  Widget build(BuildContext context) {
    String weekdays = _formatWeekdays(task['weekdays']);

    return GestureDetector(
      onTap: () => onEnabledChanged(task),
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: task['enabled']
                    ? const Icon(
                        CupertinoIcons.checkmark_alt,
                        color: AppColors.primaryAction,
                        size: 22,
                      )
                    : null,
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                            "${task['hour'].toString().padLeft(2, "0")}:${task['min'].toString().padLeft(2, "0")}"),
                        const SizedBox(
                          width: 5,
                        ),
                        Label(
                            task['type'] == "power_on" ? "开机" : "关机",
                            task['type'] == "power_on"
                                ? Colors.green
                                : Colors.orangeAccent),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      weekdays,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  OutlinedButton(
                    onPressed: () => onRemove(task),
                    child: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  OutlinedButton(
                    onPressed: () => onEdit(task),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
