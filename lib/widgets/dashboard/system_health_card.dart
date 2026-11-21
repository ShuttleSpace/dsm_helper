
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/pages/control_panel/info/info.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class DashboardSystemHealthCard extends HookWidget {
  const DashboardSystemHealthCard(
      {super.key,
      required this.storageVolumes,
      required this.storageDisks,
      required this.storageSsdCaches,
      required this.systemData,
      required this.wallpaper,
      required this.sessionHostname});

  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;
  final ReadonlySignal<List> storageSsdCaches;
  final ReadonlySignal<Map> systemData;
  final ReadonlySignal<Map> wallpaper;
  final ReadonlySignal<String> sessionHostname;

  static const widget = 'SYNO.SDS.SystemInfoApp.SystemHealthWidget';

  @override
  Widget build(BuildContext context) {
    final heatDissipation = useComputed(() =>
        "${systemData['sys_temp']}℃ ${systemData['temperature_warning'] == null ? (systemData['sys_temp'] > 80 ? "警告" : "正常") : (systemData['temperature_warning'] ? "警告" : "正常")}");
    return GestureDetector(
      onTap: () {
        if (connectionStore.notVisitorAccount.value) {
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return SystemInfo(0, systemData, storageVolumes,
                storageDisks);
          }));
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              /* wallpaper */
              Watch((context) {
                final customize = wallpaper.select((v) =>
                    v['customizeWallpaper'] == true ||
                    v['customizeBackground'] == true);
                if (settingsStore.showWallpaper.value && customize.value) {
                  return ExtendedImage.network(
                    AppConstants.wallpaper,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20),
                  );
                }
                return const SizedBox.shrink();
              }),
              /* dark theme */
              Builder(builder: (context) {
                if (Theme.brightnessOf(context) == Brightness.dark) {
                  return Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              "assets/icons/info.png",
                              width: 26,
                              height: 26,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "系统状态",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // product model
                        Watch<Widget>((context) {
                          final model =
                              systemData.select((v) => v['model']);
                          if (model.value != null) {
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  const Text("产品型号："),
                                  Text("${model.value}"),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(
                          height: 5,
                        ),
                        Watch<Widget>(
                          (context) => Row(
                            children: [
                              const Text("系统名称："),
                              Text(sessionHostname.value),
                            ],
                          ),
                        ),
                        // 散热
                        Watch<Widget>((context) {
                          final sysTemp =
                              systemData.select((v) => v['sys_temp']);
                          final temperatureWarning = systemData
                              .select((v) => v['temperature_warning']);
                          if (sysTemp.value != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  const Text("散热状态："),
                                  Text(
                                    heatDissipation.value,
                                    style: TextStyle(
                                        color: sysTemp.value == null
                                            ? (sysTemp.value > 80
                                                ? context.errorColor
                                                : context.successColor)
                                            : (temperatureWarning.value
                                                ? context.errorColor
                                                : context.successColor)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),
                        // 运行时间
                        Watch<Widget>((context) {
                          final upTime =
                              systemData.select((v) => v['up_time']);
                          if (upTime.value != null && upTime.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  const Text("运行时间："),
                                  Text(parseOpTime(upTime.value)),
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        })
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

