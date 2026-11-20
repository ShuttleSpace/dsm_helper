import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/chart_card.dart';

/// 磁盘图表组件
class DiskChart extends StatelessWidget {
  final List disks;
  final int maxReadSpeed;
  final int maxWriteSpeed;
  final List<Color> colors;

  const DiskChart({
    super.key,
    required this.disks,
    required this.maxReadSpeed,
    required this.maxWriteSpeed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? AppColors.chartGrid : AppColors.chartGrid;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return ChartCard(
      title: "磁盘",
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "读取: ${_formatSpeed(maxReadSpeed)}",
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: textColor,
              ),
            ),
            Text(
              "写入: ${_formatSpeed(maxWriteSpeed)}",
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
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
          maxX: (disks.length - 1).toDouble(),
          minY: 0,
          maxY: maxReadSpeed > maxWriteSpeed
              ? maxReadSpeed.toDouble()
              : maxWriteSpeed.toDouble(),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars() {
    if (disks.isEmpty) return [];

    List<FlSpot> readSpots = [];
    List<FlSpot> writeSpots = [];

    for (var disk in disks) {
      readSpots.add(FlSpot(
        readSpots.length.toDouble(),
        (disk['read'] as num).toDouble(),
      ));
      writeSpots.add(FlSpot(
        writeSpots.length.toDouble(),
        (disk['write'] as num).toDouble(),
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
        spots: readSpots,
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
        spots: writeSpots,
      ),
    ];
  }

  String _formatSpeed(int bytes) {
    if (bytes < 1024) return '$bytes B/s';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}
