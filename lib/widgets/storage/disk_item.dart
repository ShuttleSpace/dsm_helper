import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/widgets/button_style.dart';
import 'package:garden/widgets/label.dart';
import 'package:flutter/material.dart';

class DiskItem extends StatelessWidget {
  final Map<String, dynamic> disk;
  final List<Map<String, dynamic>> storagePools;
  final List<Map<String, dynamic>> ssdCaches;
  final bool full;

  const DiskItem({
    super.key,
    required this.disk,
    required this.storagePools,
    required this.ssdCaches,
    this.full = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: full
          ? () {
              // Navigation handled by parent
            }
          : null,
      child: Card(
        shape: context.stadiumShapeBorder,
        margin: const EdgeInsets.only(top: 10),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            children: [
              _buildBasicInfo(),
              if (full) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      _buildInfoRow("位置", disk['container']['str']),
                      const SizedBox(height: 5),
                      _buildInfoRow("硬盘类型", disk['diskType']),
                      const SizedBox(height: 5),
                      _buildStoragePoolRow(),
                      const SizedBox(height: 5),
                      _buildStatusRow(
                        "硬盘分配状态",
                        _getDiskAllocationStatus(),
                        disk['status'] == "normal",
                      ),
                      const SizedBox(height: 5),
                      _buildStatusRow(
                        "健康状态",
                        _getHealthStatus(),
                        disk['smart_status'] == "normal",
                      ),
                      if (disk['remain_life'] != null) ...[
                        const SizedBox(height: 5),
                        _buildInfoRow(
                          "预计寿命",
                          disk['remain_life'] == -1 ? "-" : disk['remain_life'],
                        ),
                      ],
                      if (disk['unc'] != null && disk['unc'] > -1) ...[
                        const SizedBox(height: 5),
                        _buildInfoRow("坏扇区数量", disk['unc']),
                      ],
                      if (disk['temp'] != null) ...[
                        const SizedBox(height: 5),
                        _buildInfoRow(
                          "温度",
                          disk['temp'] > -1 ? "${disk['temp']} ℃" : "-",
                        ),
                      ],
                      if (disk['serial'] != null) ...[
                        const SizedBox(height: 5),
                        _buildInfoRow("序列号", disk['serial']),
                      ],
                      if (disk['firm'] != null) ...[
                        const SizedBox(height: 5),
                        _buildInfoRow("固件版本", disk['firm']),
                      ],
                      if (disk['is4Kn'] != null)
                        Row(
                          children: [
                            const SizedBox(width: 150),
                            const Text(
                              "4K原生硬盘",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(disk['is4Kn'] ? "是" : "否"),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Row(
      children: [
        Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.all(10),
          child: Image.asset(
            disk['isSsd'] ? "assets/icons/ssd.png" : "assets/icons/hdd.png",
            width: 40,
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
                    "${disk['longName'].replaceAll("Cache device", "缓存设备")}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 5),
                  Label(
                    disk['overview_status'] == "normal"
                        ? "正常"
                        : disk['overview_status'],
                    disk['overview_status'] == "normal"
                        ? Colors.green
                        : Colors.red,
                    fill: true,
                  ),
                  const SizedBox(width: 5),
                  if (disk['temp'] != null && disk['temp'] > -1)
                    Label(
                      "${disk['temp']}℃",
                      Colors.lightBlueAccent,
                      height: 23,
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text("${disk['vendor'].trim()} ${disk['model'].trim()}"),
              const SizedBox(height: 5),
              Text(int.parse(disk['size_total']).formatSize()),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, bool isNormal) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: isNormal ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  Widget _buildStoragePoolRow() {
    String poolName = "-";

    var pools =
        storagePools.where((pool) => pool['id'] == disk['used_by']).toList();
    if (pools.isNotEmpty) {
      poolName = "存储池 ${pools[0]['num_id']}";
    } else {
      var ssds =
          ssdCaches.where((ssd) => ssd['id'] == disk['used_by']).toList();
      if (ssds.isNotEmpty) {
        poolName = ssds[0]['id'].toString().replaceFirst("ssd_", "SSD 缓存 ");
      }
    }

    return _buildInfoRow("存储池", poolName);
  }

  String _getDiskAllocationStatus() {
    switch (disk['status']) {
      case "normal":
        return "正常";
      case "not_use":
        return "未初始化";
      case "sys_partition_normal":
        return "已初始化";
      default:
        return disk['status'];
    }
  }

  String _getHealthStatus() {
    return disk['smart_status'] == "normal" ? "正常" : disk['smart_status'];
  }
}
