import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/control_panel/external_device/external_device.dart';
import 'package:garden/pages/dashborad/media_converter.dart';
import 'package:garden/pages/notify/notify.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/dashboard/esata_device_card.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class DashboardAppbarTitleExternalDevice extends HookWidget {
  const DashboardAppbarTitleExternalDevice({super.key, this.onEjectSuccess});

  final VoidCallback? onEjectSuccess;

  @override
  Widget build(BuildContext context) {
    final esatas = useListSignal([]);
    final usbs = useListSignal([]);
    final externalDevices = useComputed(() => esatas.value + usbs.value);

    void onExternalDeviceClick() {
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Material(
            color: Colors.transparent,
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        "外接设备",
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ...externalDevices.value.map((esata) => ESataDeviceCard(
                            esata: esata,
                            onEjectSuccess: onEjectSuccess,
                          )),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).push(CupertinoPageRoute(
                                    builder: (context) {
                                      return const ExternalDevice();
                                    },
                                    settings: const RouteSettings(
                                        name: "external_device")));
                              },
                              child: const Text(
                                "查看详情",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "取消",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    useEffect(() {
      (() async {
        try {
          final res = await dsmCoreExternalDeviceList();
          List result = res['result'] as List? ?? [];
          if (res['has_fail'] == true) {
            Log.error('dsmCoreExternalDeviceList has_fail: ${res['has_fail']}');
          }
          for (final item in result) {
            if (item['success'] == true) {
              switch (item['api']) {
                case dsmCoreExternalDeviceStorageESATA:
                  if (item['success'] == true) {
                    final devices = item['data']?['devices'];
                    esatas.value = devices is List ? devices : [];
                  } else {
                    Log.error('$dsmCoreExternalDeviceStorageESATA list failed.');
                  }
                  break;
                case dsmCoreExternalDeviceStorageUSB:
                  if (item['success'] == true) {
                    final devices = item['data']?['devices'];
                    usbs.value = devices is List ? devices : [];
                  } else {
                    Log.error('$dsmCoreExternalDeviceStorageUSB list failed.');
                  }
                  break;
              }
            }
          }
        } catch (e) {
          Log.error("getExternalDevice error: $e");
        }
      })();
      return null;
    }, const []);

    if (externalDevices.value.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
        child: OutlinedButton(
          onPressed: onExternalDeviceClick,
          child: Image.asset(
            "assets/icons/external_devices.png",
            width: 20,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class DashboardAppbarTitleDrawer extends StatelessWidget {
  const DashboardAppbarTitleDrawer({super.key, this.onOpenDrawer});
  final VoidCallback? onOpenDrawer;
  @override
  Widget build(BuildContext context) {
    if (connectionStore.notVisitorAccount.watch(context)) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
        child: OutlinedButton(
          onPressed: () {
            onOpenDrawer?.call();
          },
          child: Image.asset(
            "assets/icons/application.png",
            width: 20,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class DashboardAppbarTitleMediaConverter extends HookWidget {
  const DashboardAppbarTitleMediaConverter({super.key});

  @override
  Widget build(BuildContext context) {
    final converter = useMapSignal({});

    fetchMediaIndexingMediaConverterStatus() async {
      try {
        final res = await dsmCoreMediaIndexingMediaConverter('status');
        converter.value = res;
        final totalRemain = (converter['photo_remain'] ?? 0) +
            (converter['thumb_remain'] ?? 0) +
            (converter['video_remain'] ?? 0);
        if (totalRemain > 0) {
          UiUtil.toast(
              "${converter['photo_remain']} 张照片, ${converter['thumb_remain']} 张缩略图, ${converter['video_remain']} 个视频正在扫描转换");
          Log.info(
              "${converter['photo_remain']} 张照片, ${converter['thumb_remain']} 张缩略图, ${converter['video_remain']} 个视频正在扫描转换");
          // TODO: 可调节速度
        }
      } catch (e) {
        Log.error("getMediaConverter error: $e");
        UiUtil.toast("getMediaConverter error: $e");
        // TODO: retry???
      }
    }

    useEffect(() {
      fetchMediaIndexingMediaConverterStatus();
      return null;
    }, const []);

    if ((converter['photo_remain'] ?? 0) +
            (converter['thumb_remain'] ?? 0) +
            (converter['video_remain'] ?? 0) >
        0) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
        child: OutlinedButton(
          onPressed: () {
            showCupertinoModalPopup(
                context: context,
                builder: (context) {
                  return MediaConverter(converter);
                });
          },
          child: Image.asset(
            "assets/icons/converter.gif",
            width: 20,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class DashboardAppbarTitleEdit extends StatelessWidget {
  const DashboardAppbarTitleEdit({super.key, this.onEditClick});
  final VoidCallback? onEditClick;

  @override
  Widget build(BuildContext context) {
    if (connectionStore.notVisitorAccount.watch(context)) {
      return Padding(
        padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        child: OutlinedButton(
          onPressed: onEditClick,
          child: Image.asset(
            "assets/icons/edit.png",
            width: 20,
            height: 20,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class DashboardAppbarTitleNotifier extends HookWidget {
  const DashboardAppbarTitleNotifier({super.key});

  @override
  Widget build(BuildContext context) {
    final notifies = useListSignal([]);

    fetchNotifies() async {
      try {
        final res = await dsmCoreDSMNotify('load');
        return res['items'];
      } catch (e) {
        Log.error('fetchNotifies error: $e');
        return [];
      }
    }

    useEffect(() {
      (() async {
        final res = await fetchNotifies();
        notifies.value = res;
        // Log.info('notifies1: $res');
      })();
      return null;
    }, const []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context)
              .push(CupertinoPageRoute(
                  builder: (context) {
                    return Notify(notifies.value);
                  },
                  settings: const RouteSettings(name: "notify")))
              .then((res) {
            if (res != null && res) {
              notifies.value.clear();
            }
          });
        },
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Image.asset(
              "assets/icons/message.png",
              width: 20,
              height: 20,
            ),
            if (notifies.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(18),
                ),
                width: 5,
                height: 5,
              )
          ],
        ),
      ),
    );
  }
}