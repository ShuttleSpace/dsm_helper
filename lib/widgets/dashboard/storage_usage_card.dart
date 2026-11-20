
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/pages/control_panel/info/info.dart';
import 'package:garden/widgets/label.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:garden/widgets/dashboard/dashboard_card_parts.dart';

class DashboardStorageUsageCard extends StatelessWidget {
  const DashboardStorageUsageCard(
      {super.key,
      required this.sdsWidgetModuleList,
      required this.systemData,
      required this.appNotify,
      required this.storageVolumes,
      required this.storageDisks,
      required this.storageSsdCaches});
  final ReadonlySignal<List> sdsWidgetModuleList;
  final ReadonlySignal<Map> systemData;
  final ReadonlySignal<Map> appNotify;
  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;
  final ReadonlySignal<List> storageSsdCaches;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
              return SystemInfo(2, systemData, storageVolumes, storageDisks);
            }));
          },
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/pie.png",
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          "存储",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const DashboardCardItemCollapse("StorageUsage")
                      ],
                    ),
                  ),
                  Builder(builder: (context) {
                    if (storageVolumes.watch(context).isEmpty) {
                      return const Text.rich(TextSpan(
                        text: '暂无存储数据',
                      ));
                    }
                    if (context.isCardItemCollapsed('StorageUsage')) {
                      return Flexible(
                        child: Column(
                          children: storageVolumes
                              .map((e) => _DashboardStorageVolumeItem(
                                  (e as Map).toSignal()))
                              .toList(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (storageSsdCaches.watch(context).isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
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
                          "assets/icons/cache.png",
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          "缓存",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const DashboardCardItemCollapse("StorageUsage")
                      ],
                    ),
                  ),
                  Builder(builder: (context) {
                    if (storageSsdCaches.watch(context).isEmpty) {
                      return const Text.rich(TextSpan(
                        text: '暂无缓存数据',
                      ));
                    }
                    if (context.isCardItemCollapsed('StorageUsage')) {
                      return Flexible(
                          child: Column(
                        children: storageSsdCaches
                            .map((e) => _DashboardStorageSsdCacheItem(e))
                            .toList(),
                      ));
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }
}

class _DashboardStorageVolumeItem extends StatelessWidget {
  const _DashboardStorageVolumeItem(this.volume);
  final ReadonlySignal<Map> volume;
  @override
  Widget build(BuildContext context) {
    final used = volume.select((v) =>
        int.parse(v['size']?['used'] ?? '0') /
        int.parse(v['size']?['total'] ?? '1'));
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(5)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 40,
              animation: true,
              linearGradient: LinearGradient(
                colors: used.watch(context) <= 0.9
                    ? [
                        Colors.blue,
                        Colors.blueAccent,
                      ]
                    : [
                        Colors.red,
                        Colors.orangeAccent,
                      ],
              ),
              animateFromLastPercent: true,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 12,
              backgroundColor: Colors.black12,
              percent: used.watch(context),
              center: Text(
                "${(used.watch(context) * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                    color:
                        used.watch(context) <= 0.9 ? Colors.blue : Colors.red,
                    fontSize: 22),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        volume.select((v) => v['deploy_path'] ?? '').value !=
                                null
                            ? volume
                                .select((v) => v['deploy_path'] ?? '')
                                .value
                                .toString()
                                .replaceFirst("volume_", "存储空间 ")
                            : volume
                                .select((v) => v['id'] ?? '')
                                .value
                                .toString()
                                .replaceFirst("volume_", "存储空间 "),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Builder(builder: (context) {
                        final status = volume.select((v) => v['status']);
                        return status.watch(context) == "normal"
                            ? const Label(
                                "正常",
                                Colors.green,
                                fill: true,
                              )
                            : status.value == "background"
                                ? const Label(
                                    "正在检查硬盘",
                                    Colors.lightBlueAccent,
                                    fill: true,
                                  )
                                : status.value == "attention"
                                    ? const Label(
                                        "注意",
                                        Colors.orangeAccent,
                                        fill: true,
                                      )
                                    : Label(
                                        status.value,
                                        Colors.red,
                                        fill: true,
                                      );
                      })
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                      "已用：${int.parse(volume.select((v) => v['size']?['used'] ?? '0').watch(context)).formatSize()}"),
                  const SizedBox(
                    height: 5,
                  ),
                  Builder(builder: (context) {
                    final total =
                        volume.select((v) => v['size']?['total'] ?? '0');
                    final used =
                        volume.select((v) => v['size']?['used'] ?? '0');
                    return Text(
                      "可用：${(int.parse(total.watch(context)) - int.parse(used.watch(context))).formatSize()}",
                    );
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                      "容量：${int.parse(volume.select((v) => v['size']?['total'] ?? '0').watch(context)).formatSize()}"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _DashboardStorageSsdCacheItem extends StatelessWidget {
  const _DashboardStorageSsdCacheItem(this.ssd);
  final ReadonlySignal<Map> ssd;
  @override
  Widget build(BuildContext context) {
    final percent = ssd.select((v) =>
        int.parse(v['size']?['used'] ?? v['size']?['reusable'] ?? '0') /
        int.parse(v['size']?['total'] ?? '1'));
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 40,
              animation: true,
              linearGradient: LinearGradient(
                colors: percent.watch(context) <= 0.9
                    ? [
                        Colors.blue,
                        Colors.blueAccent,
                      ]
                    : [
                        Colors.red,
                        Colors.orangeAccent,
                      ],
              ),
              animateFromLastPercent: true,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 12,
              backgroundColor: Colors.black12,
              percent: percent.watch(context),
              center: Text(
                "${(percent.watch(context) * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                    color: percent.watch(context) <= 0.9
                        ? Colors.blue
                        : Colors.red,
                    fontSize: 22),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ssd
                            .select((v) => v['id'] ?? '')
                            .toString()
                            .replaceFirst("ssd_", "SSD 缓存 "),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Builder(builder: (context) {
                        final status = ssd.select((v) => v['status']);
                        return status.watch(context) == "normal"
                            ? const Label(
                                "正常",
                                Colors.green,
                                fill: true,
                              )
                            : status.watch(context) == "background"
                                ? const Label(
                                    "正在检查硬盘",
                                    Colors.lightBlueAccent,
                                    fill: true,
                                  )
                                : status.watch(context) == "attention"
                                    ? const Label(
                                        "注意",
                                        Colors.orangeAccent,
                                        fill: true,
                                      )
                                    : Label(
                                        status.watch(context),
                                        Colors.red,
                                        fill: true,
                                      );
                      }),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Watch((context) {
                    final used = ssd.select((v) => v['size']?['used']);
                    final reusable = ssd.select((v) => v['size']?['reusable']);
                    return Text(
                        "已用：${int.parse(used.value ?? reusable.value ?? '0').formatSize()}");
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  Watch((context) {
                    final total = ssd.select((v) => v['size']?['total'] ?? '0');
                    final used = ssd.select((v) => v['size']?['used']);
                    final reusable = ssd.select((v) => v['size']?['reusable']);
                    return Text(
                      "可用：${(int.parse(total.value) - int.parse(used.value ?? reusable.value ?? '0')).formatSize()}",
                    );
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                      "容量：${int.parse(ssd.select((v) => v['size']?['total'] ?? '0').value).formatSize()}"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

