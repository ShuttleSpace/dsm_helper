import 'package:flutter/cupertino.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/resource_monitor/widgets/network_chart.dart';

/// 网络标签页组件
class NetworkTab extends StatelessWidget {
  const NetworkTab({
    super.key,
    required this.loading,
    required this.networks,
    required this.maxSpeed,
    required this.colors,
  });

  final bool loading;
  final List networks;
  final int maxSpeed;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CupertinoActivityIndicator(radius: 14))
        : ListView(
            children: [
              const SizedBox(height: AppConstants.paddingMedium),
              NetworkChart(
                networks: networks,
                maxSpeed: maxSpeed,
                colors: colors,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
            ],
          );
  }
}
