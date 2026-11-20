import 'package:flutter/cupertino.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/resource_monitor/widgets/cpu_chart.dart';

/// CPU 标签页组件
class CpuTab extends StatelessWidget {
  const CpuTab({
    super.key,
    required this.loading,
    required this.cpus,
    required this.colors,
  });

  final bool loading;
  final List cpus;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CupertinoActivityIndicator(radius: 14))
        : ListView(
            children: [
              const SizedBox(height: AppConstants.paddingMedium),
              CpuChart(
                cpus: cpus,
                colors: colors,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
            ],
          );
  }
}
