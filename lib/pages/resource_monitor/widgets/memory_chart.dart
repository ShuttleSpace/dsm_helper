import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/chart_card.dart';

/// 内存图表组件
class MemoryChart extends StatelessWidget {
  final List memories;
  final List<Color> colors;

  const MemoryChart({
    super.key,
    required this.memories,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? AppColors.chartGrid : AppColors.chartGrid;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return ChartCard(
      title: "内存",
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
          maxX: (memories.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars() {
    if (memories.isEmpty) return [];

    List<FlSpot> spots = [];
    List<FlSpot> swapSpots = [];

    for (var memory in memories) {
      spots.add(FlSpot(
        spots.length.toDouble(),
        (memory['memory_usage_real'] as num).toDouble(),
      ));
      swapSpots.add(FlSpot(
        swapSpots.length.toDouble(),
        (memory['memory_swap_cached'] as num).toDouble(),
      ));
    }

    return [
      LineChartBarData(
        isCurved: true,
        color: colors[0],
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: colors[0].withValues(alpha: .3),
        ),
        spots: spots,
      ),
      LineChartBarData(
        isCurved: true,
        color: colors[1],
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: colors[1].withValues(alpha: .3),
        ),
        spots: swapSpots,
      ),
    ];
  }
}
