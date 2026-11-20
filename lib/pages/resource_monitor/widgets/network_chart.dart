import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/chart_card.dart';

/// 网络图表组件
class NetworkChart extends StatelessWidget {
  final List networks;
  final int maxSpeed;
  final List<Color> colors;

  const NetworkChart({
    super.key,
    required this.networks,
    required this.maxSpeed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? AppColors.chartGrid : AppColors.chartGrid;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return ChartCard(
      title: "网络",
      actions: [
        Text(
          "最大: ${_formatSpeed(maxSpeed)}",
          style: TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: textColor,
          ),
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
          maxX: (networks.length - 1).toDouble(),
          minY: 0,
          maxY: maxSpeed.toDouble(),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars() {
    if (networks.isEmpty) return [];

    List<FlSpot> downloadSpots = [];
    List<FlSpot> uploadSpots = [];

    for (var network in networks) {
      downloadSpots.add(FlSpot(
        downloadSpots.length.toDouble(),
        (network['download'] as num).toDouble(),
      ));
      uploadSpots.add(FlSpot(
        uploadSpots.length.toDouble(),
        (network['upload'] as num).toDouble(),
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
        spots: downloadSpots,
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
        spots: uploadSpots,
      ),
    ];
  }

  String _formatSpeed(int bytes) {
    if (bytes < 1024) return '$bytes B/s';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}
