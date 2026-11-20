import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 图表卡片组件
///
/// 封装通用的图表展示卡片，包含标题和图表内容
class ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final double aspectRatio;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final List<Widget>? actions;

  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.aspectRatio = 1.70,
    this.height,
    this.padding,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.cardMargin),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.paddingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (height != null)
              SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge),
                  child: chart,
                ),
              )
            else
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppConstants.paddingLarge,
                    right: AppConstants.paddingLarge,
                    top: AppConstants.paddingMedium,
                    bottom: AppConstants.paddingSmall,
                  ),
                  child: chart,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 线图配置工具类
class LineChartConfig {
  /// 获取默认的网格线样式
  static FlGridData getGridData({
    required Color color,
    bool show = true,
    int interval = 3,
  }) {
    return FlGridData(
      show: show,
      drawVerticalLine: false,
      horizontalInterval: interval.toDouble(),
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: color,
          strokeWidth: 1,
        );
      },
    );
  }

  /// 获取默认的边距
  static FlBorderData getBorderData({required Color color}) {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: color,
        width: 1,
      ),
    );
  }

  /// 获取默认的标题样式
  static AxisTitles getAxisTitles({
    required Color color,
    bool show = true,
    String? title,
  }) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: show,
        reservedSize: title != null ? 30 : 0,
        getTitlesWidget: (value, meta) {
          if (title != null && meta.max == 0) {
            return Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: AppConstants.fontSizeSmall,
              ),
            );
          }
          return Text(
            value.toInt().toString(),
            style: TextStyle(
              color: color,
              fontSize: AppConstants.fontSizeSmall,
            ),
          );
        },
      ),
    );
  }

  /// 获取默认的线条样式
  static LineTouchData getTouchData({
    bool enabled = true,
    List<LineBarSpot>? spots,
  }) {
    return LineTouchData(
      enabled: enabled,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: .8),
      ),
    );
  }
}

/// 饼图配置工具类
class PieChartConfig {
  /// 获取默认的边距
  static EdgeInsets getPadding() {
    return const EdgeInsets.all(AppConstants.paddingMedium);
  }

  /// 获取默认的标题样式
  static TextStyle getTitleStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: AppConstants.fontSizeSmall,
      fontWeight: FontWeight.bold,
    );
  }

  /// 获取默认的指示器半径
  static double getIndicatorRadius() {
    return AppConstants.paddingSmall;
  }

  /// 获取默认的指示器宽度
  static double getIndicatorWidth() {
    return AppConstants.paddingSmall / 2;
  }
}
