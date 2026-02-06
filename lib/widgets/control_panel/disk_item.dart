import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/label.dart';
import 'info_card.dart';

/// 硬盘项组件
/// 用于显示单个硬盘的详细信息
class DiskItem extends StatelessWidget {
  /// 硬盘数据
  final Map<String, dynamic> disk;

  const DiskItem({
    super.key,
    required this.disk,
  });

  @override
  Widget build(BuildContext context) {
    final isSsd = disk['isSsd'] ?? false;
    final status = disk['overview_status'] ?? "unknown";
    final isNormal = status == "normal";
    final totalSize = int.tryParse(disk['size_total'] ?? '0') ?? 0;
    final temp = disk['temp'] ?? 0;

    return InfoCard(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Row(
        children: [
          InfoCard(
            showBorder: true,
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Image.asset(
                isSsd ? "assets/icons/ssd.png" : "assets/icons/hdd.png",
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
                      disk['longName'] ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5),
                    Label(
                      isNormal ? "正常" : status,
                      isNormal ? Colors.green : Colors.red,
                      fill: true,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                    "${disk['vendor']?.trim() ?? ''} ${disk['model']?.trim() ?? ''}"),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(totalSize.formatSize()),
                    Text("  $temp℃"),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
