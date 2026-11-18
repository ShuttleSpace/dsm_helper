import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/dashborad/dashboard_monitor_resource_widget.dart';
import 'package:garden/pages/resource_monitor/resource_monitor.dart';
import 'package:garden/util/log.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:garden/widgets/dashboard/dashboard_card_parts.dart';

class DashboardResourceMonitorCard extends HookWidget {
  const DashboardResourceMonitorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final monitoredResources = useMapSignal({});
    final error = useSignal('');

    final networks = useMemoized(
        () => List.generate(20, (i) => {"tx": 0, "rx": 0}), const []);

    int maxNetworkSpeed() {
      int maxSpeed = 0;
      for (int i = 0; i < networks.length; i++) {
        int maxVal = max(networks[i]['rx'] ?? 0, networks[i]['tx'] ?? 0);
        if (maxSpeed < maxVal) {
          maxSpeed = maxVal;
        }
      }
      return maxSpeed;
    }

    fetchData() {
      dsmCoreSystemUtilization(
          ["cpu", "memory", "network", "lun", "disk", "space"]).then((res) {
        monitoredResources.value = res as Map<String, dynamic>;
        if (networks.length > 20) {
          networks.removeAt(0);
        }
        Log.debug('🌊: ${monitoredResources.isEmpty}');
        final networkData = res['network'][0] as Map;
        networks.add({
          "tx": (networkData['tx'] as num?)?.toInt() ?? 0,
          "rx": (networkData['rx'] as num?)?.toInt() ?? 0
        });
      }).catchError((e) {
        error.value = e.toString();
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return const ResourceMonitor();
        }));
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/resources.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "资源监控",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const DashboardCardItemCollapse("ResourceMonitor")
                  ],
                ),
              ),
              Builder(builder: (context) {
                if (monitoredResources.watch(context).isEmpty) {
                  return TextButton(
                      onPressed: fetchData,
                      child: Text.rich(TextSpan(
                          text: error.isEmpty ? '暂时获取不到系统数据' : error.value,
                          children: [
                            TextSpan(
                                text: '\t\t点击重试',
                                style: dashboardRetryTextStyle(context))
                          ])));
                }
                if (context.isCardItemCollapsed('ResourceMonitor')) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      PerformanceCpuWidget(
                          monitoredResources: monitoredResources),
                      const SizedBox(
                        height: 15,
                      ),
                      PerformanceRamWidget(
                          monitoredResources: monitoredResources),
                      const SizedBox(
                        height: 15,
                      ),
                      PerformanceNetowrkWidget(
                          monitoredResources: monitoredResources),
                      const SizedBox(
                        height: 15,
                      ),
                      PerformanceNetworkChartWidget(
                          networks: networks, maxNetworkSpeed: maxNetworkSpeed())
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

