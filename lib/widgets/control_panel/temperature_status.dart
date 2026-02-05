import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'info_row.dart';

/// 温度状态指示器组件
/// 用于显示温度及其状态
class TemperatureStatus extends StatelessWidget {
  /// 温度值（摄氏度）
  final int? temperature;

  /// 温度警告标志
  final bool? temperatureWarning;

  /// 警告阈值
  final int warningThreshold;

  const TemperatureStatus({
    super.key,
    required this.temperature,
    this.temperatureWarning,
    this.warningThreshold = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (temperature == null) return const SizedBox.shrink();

    final isWarning = temperatureWarning ?? (temperature! > warningThreshold);
    final statusText = isWarning ? "警告" : "正常";
    final statusColor = isWarning ? Colors.red : Colors.green;

    return InfoRow(
      label: "散热状态",
      value: "$temperature℃ $statusText",
      valueStyle: TextStyle(color: statusColor),
    );
  }
}

/// 带边框的温度状态指示器组件
class BorderedTemperatureStatus extends StatelessWidget {
  /// 温度值（摄氏度）
  final int? temperature;

  /// 温度警告标志
  final bool? temperatureWarning;

  /// 警告阈值
  final int warningThreshold;

  const BorderedTemperatureStatus({
    super.key,
    required this.temperature,
    this.temperatureWarning,
    this.warningThreshold = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (temperature == null) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: TemperatureStatus(
          temperature: temperature,
          temperatureWarning: temperatureWarning,
          warningThreshold: warningThreshold,
        ),
      ),
    );
  }
}
