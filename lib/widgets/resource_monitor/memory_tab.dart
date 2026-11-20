import 'package:flutter/cupertino.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/resource_monitor/widgets/memory_chart.dart';

/// 内存标签页组件
class MemoryTab extends StatelessWidget {
  const MemoryTab({
    super.key,
    required this.loading,
    required this.memories,
    required this.colors,
  });

  final bool loading;
  final List memories;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CupertinoActivityIndicator(radius: 14))
        : ListView(
            children: [
              const SizedBox(height: AppConstants.paddingMedium),
              MemoryChart(
                memories: memories,
                colors: colors,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
            ],
          );
  }
}
