import 'package:garden/widgets/label.dart';
import 'package:garden/util/format_util.dart';
import 'package:garden/widgets/storage/volume_item.dart';
import 'package:garden/widgets/storage/disk_item.dart';
import 'package:flutter/material.dart';

class PoolDetail extends StatelessWidget {
  final Map<String, dynamic> pool;
  final List<Map<String, dynamic>> disks;
  final List<Map<String, dynamic>> volumes;
  final List<Map<String, dynamic>> ssdCaches;

  const PoolDetail({
    super.key,
    required this.pool,
    required this.disks,
    required this.volumes,
    required this.ssdCaches,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> poolDisks =
        disks.where((e) => pool['disks'].contains(e['id'])).toList();
    List<Map<String, dynamic>> poolVolumes =
        volumes.where((e) => e['pool_path'] == pool['id']).toList();

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            _buildDeviceTypeSection(),
            const SizedBox(height: 5),
            _buildInfoRow("支持多个存储空间",
                pool['raidType'] == "single" ? "否" : "是"),
            const SizedBox(height: 5),
            _buildAvailableCapacityRow(),
            const SizedBox(height: 20),
            _buildDisksSection(poolDisks),
            const SizedBox(height: 20),
            _buildHotSpareSection(),
            const SizedBox(height: 20),
            _buildAllocationSection(poolVolumes),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          "存储池 ${pool['num_id']}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 5),
        _buildStatusLabel(pool['status']),
        const Spacer(),
        Text(
            "${FormatUtil.formatSize(int.parse(pool['size']['used']))} / ${FormatUtil.formatSize(int.parse(pool['size']['total']))}"),
      ],
    );
  }

  Widget _buildDeviceTypeSection() {
    return Row(
      children: [
        Text(
          _getDeviceTypeText(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (pool['device_type'] == "basic" ||
            pool['device_type'] == "shr_without_disk_protect")
          const Text(
            "（无数据保护）",
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
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

  Widget _buildAvailableCapacityRow() {
    return _buildInfoRow(
      "可用容量",
      FormatUtil.formatSize(
          int.parse(pool['size']['total']) - int.parse(pool['size']['used'])),
    );
  }

  Widget _buildDisksSection(List<Map<String, dynamic>> poolDisks) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "硬盘信息",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...poolDisks.map((disk) => DiskItem(
                  disk: disk,
                  storagePools: const [],
                  ssdCaches: ssdCaches,
                  full: false,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHotSpareSection() {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "可用Hot Spare硬盘",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                    pool['spares'] == null || pool['spares'].length == 0 ? "系统中无备援配置" : "暂不支持显示，共${pool['spares'].length}块"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationSection(List<Map<String, dynamic>> poolVolumes) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "存储分配",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...poolVolumes.map((volume) => VolumeItem(volume: volume)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel(String status) {
    switch (status) {
      case "normal":
        return const Label(
          "正常",
          Colors.green,
          fill: true,
        );
      case "background":
        return const Label(
          "正在检查硬盘",
          Colors.lightBlueAccent,
          fill: true,
        );
      case "attention":
        return const Label(
          "注意",
          Colors.orangeAccent,
          fill: true,
        );
      default:
        return Label(
          status,
          Colors.red,
          fill: true,
        );
    }
  }

  String _getDeviceTypeText() {
    switch (pool['device_type']) {
      case "basic":
        return "Basic";
      case "shr_without_disk_protect":
      case "shr":
        return "Synology Hybrid RAID (SHR) ";
      default:
        return pool['device_type'];
    }
  }
}