import 'package:flutter/cupertino.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/resource_monitor/widgets/disk_chart.dart';

/// 磁盘标签页组件
class DiskTab extends StatelessWidget {
  const DiskTab({
    super.key,
    required this.loading,
    required this.disks,
    required this.maxReadSpeed,
    required this.maxWriteSpeed,
    required this.colors,
  });

  final bool loading;
  final List disks;
  final int maxReadSpeed;
  final int maxWriteSpeed;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CupertinoActivityIndicator(radius: 14))
        : ListView(
            children: [
              const SizedBox(height: AppConstants.paddingMedium),
              DiskChart(
                disks: disks,
                maxReadSpeed: maxReadSpeed,
                maxWriteSpeed: maxWriteSpeed,
                colors: colors,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
            ],
          );
  }
}
