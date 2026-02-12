import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/pages/resource_monitor/performance.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:signals/signals_flutter.dart';

class PerformanceNetworkChartWidget extends StatelessWidget {
  const PerformanceNetworkChartWidget(
      {super.key, required this.networks, required this.maxNetworkSpeed});
  final List<Map<String, int>> networks;
  final int maxNetworkSpeed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 3,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: AspectRatio(
        aspectRatio: 1.70,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorder:
                          BorderSide(color: Colors.white.withValues(alpha: .6)),
                      tooltipRoundedRadius: 20,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (List<LineBarSpot> items) {
                        return items.map((LineBarSpot touchedSpot) {
                          final textStyle = TextStyle(
                            color: touchedSpot.bar.color,
                            // color: touchedSpot.bar.colors[0],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          );
                          return LineTooltipItem(
                              '${touchedSpot.bar.color == context.uploadColor ? "上传" : "下载"}:${(touchedSpot.y.floor()).formatSize()}',
                              textStyle);
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 22,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Text((value.toInt()).formatSize(fixed: 0),
                              style: TextStyle(
                                color: context.chartTextColor,
                                fontSize: 12,
                              ));
                        },
                        reservedSize: 35,
                        interval: maxNetworkSpeed.chartInterval(),
                      ),
                    ),
                  ),
                  // maxY: 20,
                  minY: 0,
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.black12, width: 1)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: networks.map((network) {
                        return FlSpot(networks.indexOf(network).toDouble(),
                            (network['tx'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.uploadColor.withValues(alpha: .2),
                      ),
                    ),
                    LineChartBarData(
                      spots: networks.map((network) {
                        return FlSpot(networks.indexOf(network).toDouble(),
                            (network['rx'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.downloadColor.withValues(alpha: .2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PerformanceNetowrkWidget extends StatelessWidget {
  const PerformanceNetowrkWidget({super.key, required this.monitoredResources});
  final ReadonlySignal<Map> monitoredResources;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 3,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: Row(
          children: [
            const SizedBox(width: 60, child: Text("网络：")),
            Icon(
              Icons.upload_sharp,
              color: context.uploadColor,
            ),
            Watch((context) {
              final tx = monitoredResources
                  .select((v) => v['network']?[0]?['tx'] ?? 0);
              return Text(
                "${tx.value.formatSize()}/S",
                style: TextStyle(color: context.uploadColor),
              );
            }),
            const SizedBox(
              width: 30,
            ),
            Icon(
              Icons.download_sharp,
              color: context.downloadColor,
            ),
            Watch((context) {
              final rx = monitoredResources
                  .select((v) => v['network']?[0]?['rx'] ?? 0);
              return Text(
                "${rx.value.formatSize()}/S",
                style: TextStyle(color: context.downloadColor),
              );
            })
          ],
        ),
      ),
    );
  }
}

class PerformanceRamWidget extends StatelessWidget {
  const PerformanceRamWidget({super.key, required this.monitoredResources});
  final ReadonlySignal<Map> monitoredResources;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 2,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: Row(children: [
          const SizedBox(width: 60, child: Text("RAM：")),
          Expanded(
            child: Watch((context) {
              final realUsage = monitoredResources
                  .select((v) => v['memory']?['real_usage'] ?? 0);
              return FAProgressBar(
                backgroundColor: Colors.transparent,
                changeColorValue: 90,
                changeProgressColor: context.errorColor,
                progressColor: context.infoColor,
                displayTextStyle: TextStyle(
                    color: AppTheme.of(context).progressColor, fontSize: 12),
                currentValue: realUsage.value,
                displayText: '%',
              );
            }),
          ),
        ]),
      ),
    );
  }
}

class PerformanceCpuWidget extends StatelessWidget {
  const PerformanceCpuWidget({super.key, required this.monitoredResources});
  final ReadonlySignal<Map> monitoredResources;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 1,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: Row(
          children: [
            const SizedBox(
              width: 60,
              child: Text("CPU："),
            ),
            Expanded(
              child: Watch((context) {
                final cpuUsage =
                    monitoredResources.select((v) => v['cpu']?['usage'] ?? 0);
                final cpuSysLoad = monitoredResources
                    .select((v) => v['cpu']?['system_load'] ?? 0);
                return FAProgressBar(
                  backgroundColor: Colors.transparent,
                  changeColorValue: 90,
                  changeProgressColor: context.errorColor,
                  progressColor: context.infoColor,
                  displayTextStyle: TextStyle(
                      color: AppTheme.of(context).progressColor, fontSize: 12),
                  currentValue: cpuUsage.value + cpuSysLoad.value,
                  displayText: '%',
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
