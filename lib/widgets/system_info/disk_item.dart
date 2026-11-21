import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/widgets/label.dart';

/// 系统信息页的磁盘卡片。
class SystemDiskItem extends StatelessWidget {
  final Map item;

  const SystemDiskItem(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18),
              ),
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Image.asset(
                  item['isSsd']
                      ? "assets/icons/ssd.png"
                      : "assets/icons/hdd.png",
                  width: 40,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${item['longName']}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 5),
                      Label(
                        item['overview_status'] == "normal"
                            ? "正常"
                            : item['overview_status'],
                        item['overview_status'] == "normal"
                            ? Colors.green
                            : Colors.red,
                        fill: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text("${item['vendor'].trim()} ${item['model'].trim()}"),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text((item['size_total'] as num).formatSize()),
                      Text("  ${item['temp']}℃"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
