import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/chart_card.dart';

/// CPU 图表组件
class CpuChart extends StatelessWidget {
  final List cpus;
  final List<Color> colors;

  const CpuChart({
    super.key,
    required this.cpus,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? AppColors.chartGrid : AppColors.chartGrid;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return ChartCard(
      title: "CPU",
      chart: LineChart(
        LineChartData(
          gridData: LineChartConfig.getGridData(color: gridColor),
          titlesData: FlTitlesData(
            leftTitles: LineChartConfig.getAxisTitles(color: textColor),
            bottomTitles: LineChartConfig.getAxisTitles(color: textColor),
            topTitles:
                LineChartConfig.getAxisTitles(show: false, color: textColor),
            rightTitles:
                LineChartConfig.getAxisTitles(show: false, color: textColor),
          ),
          borderData: LineChartConfig.getBorderData(color: gridColor),
          lineBarsData: _buildLineBars(),
          lineTouchData: LineChartConfig.getTouchData(),
          minX: 0,
          maxX: (cpus.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars() {
    if (cpus.isEmpty) return [];

    final firstCpu = cpus[0] as Map;
    final cpuCount =
        firstCpu['cpu'] != null ? (firstCpu['cpu'] as List).length : 1;

    List<LineChartBarData> bars = [];

    for (int i = 0; i < cpuCount; i++) {
      List<FlSpot> spots = [];

      for (var cpu in cpus) {
        final cpuData = cpu['cpu'] as List;
        final value = ((cpuData[i]['user'] as num) + (cpuData[i]['system'] as num)).toDouble();
        spots.add(FlSpot(spots.length.toDouble(), value));
      }

      bars.add(
        LineChartBarData(
          isCurved: true,
          color: colors[i % colors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: colors[i % colors.length].withValues(alpha: .3),
          ),
          spots: spots,
        ),
      );
    }

    return bars;
  }
}
