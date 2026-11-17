import 'package:garden/pages/control_panel/power/add_power_task.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/theme/app_theme.dart';
import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/control_panel/power_task_item.dart';
import 'package:garden/widgets/control_panel/memory_compression_card.dart';
import 'package:garden/widgets/control_panel/power_recovery_card.dart';
import 'package:garden/widgets/control_panel/beep_control_card.dart';
import 'package:garden/widgets/control_panel/fan_mode_card.dart';
import 'package:garden/widgets/control_panel/led_brightness_card.dart';
import 'package:garden/widgets/control_panel/hibernation_settings_card.dart';
import 'package:garden/widgets/control_panel/usb_hibernation_card.dart';
import 'package:garden/widgets/control_panel/auto_power_off_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Power extends HookWidget {
  const Power({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 4, vsync: tickerProvider),
      const [],
    );
    final loading = useSignal(true);
    final enableZram = useSignal(false);
    final powerRecovery = useSignal<Map>({});
    final beepControl = useSignal<Map>({});
    final fanSpeed = useSignal<Map>({});
    final hibernation = useSignal<Map>({});
    final ups = useSignal<Map>({});
    final led = useSignal<Map>({});
    final powerTasks = useSignal<List>([]);

    List dataList = [
    {
      "value": 0,
      "title": "无",
    },
    {
      "value": 10,
      "title": "10分钟",
    },
    {
      "value": 15,
      "title": "15分钟",
    },
    {
      "value": 20,
      "title": "20分钟",
    },
    {
      "value": 30,
      "title": "30分钟",
    },
    {
      "value": 60,
      "title": "1小时",
    },
    {
      "value": 120,
      "title": "2小时",
    },
    {
      "value": 180,
      "title": "3小时",
    },
    {
      "value": 240,
      "title": "4小时",
    },
    {
      "value": 300,
      "title": "5小时",
    },
    ];

    // The settings maps are edited in place; every change writes a new map so
    // the signal notifies and the page rebuilds (the old code used setState).
    void setPowerRecovery(String key, dynamic value) {
      powerRecovery.value = {...powerRecovery.value, key: value};
    }

    void setBeepControl(String key, dynamic value) {
      beepControl.value = {...beepControl.value, key: value};
    }

    void setFanSpeed(String key, dynamic value) {
      fanSpeed.value = {...fanSpeed.value, key: value};
    }

    void setLed(String key, dynamic value) {
      led.value = {...led.value, key: value};
    }

    void setHibernation(Map changes) {
      hibernation.value = {...hibernation.value, ...changes};
    }

    Future<void> getData() async {
      try {
        final apis = [
          {"api": "SYNO.Core.Hardware.ZRAM", "method": "get", "version": 1},
          {
            "api": "SYNO.Core.Hardware.PowerRecovery",
            "method": "get",
            "version": 1
          },
          {"api": "SYNO.Core.Hardware.BeepControl", "method": "get", "version": 1},
          {"api": "SYNO.Core.Hardware.FanSpeed", "method": "get", "version": 1},
          {
            "api": "SYNO.Core.Hardware.Led.Brightness",
            "method": "get",
            "version": 1
          },
          {"api": "SYNO.Core.Hardware.Hibernation", "method": "get", "version": 1},
          {"api": "SYNO.Core.ExternalDevice.UPS", "method": "get", "version": 1},
          {
            "api": "SYNO.Core.Hardware.PowerSchedule",
            "method": "load",
            "version": 1
          }
        ];
        final data = await dsmControlPanelPost({
          "stop_when_error": false,
          "api": 'SYNO.Entry.Request',
          "method": 'request',
          "mode": '"sequential"',
          "compound": jsonEncode(apis),
          "version": 1,
        });
        for (final item in data['result'] ?? []) {
          if (item is! Map || item['success'] != true) continue;
          final itemData = item['data'];
          if (itemData is! Map) continue;
          switch (item['api']) {
            case "SYNO.Core.Hardware.ZRAM":
              enableZram.value = itemData['enable_zram'] ?? false;
              break;
            case "SYNO.Core.Hardware.PowerRecovery":
              powerRecovery.value = itemData;
              break;
            case "SYNO.Core.Hardware.BeepControl":
              beepControl.value = itemData;
              break;
            case "SYNO.Core.Hardware.FanSpeed":
              fanSpeed.value = itemData;
              break;
            case "SYNO.Core.Hardware.Led.Brightness":
              led.value = itemData;
              break;
            case "SYNO.Core.ExternalDevice.UPS":
              ups.value = itemData;
              break;
            case "SYNO.Core.Hardware.PowerSchedule":
              final onTasks = (itemData['poweron_tasks'] as List? ?? [])
                  .map((e) => e..['type'] = "power_on")
                  .toList();
              final offTasks = (itemData['poweroff_tasks'] as List? ?? [])
                  .map((e) => e..['type'] = "power_off")
                  .toList();
              powerTasks.value = onTasks + offTasks;
              powerTasks.value.sort((a, b) {
                if (a['hour'] > b['hour']) return 1;
                if (a['hour'] == b['hour']) {
                  if (a['min'] > b['min']) return 1;
                  if (a['min'] < b['min']) return -1;
                  return 0;
                }
                return -1;
              });
              powerTasks.value = List.of(powerTasks.value);
              break;
            case "SYNO.Core.Hardware.Hibernation":
              hibernation.value = itemData;
              break;
          }
        }
        loading.value = false;
      } catch (e) {
        loading.value = false;
      }
    }

    useEffect(() {
      getData();
      return () {
        tabController.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("硬件和电源"),
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: TabBar(
                    dividerHeight: 0,
                    isScrollable: true,
                    controller: tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Theme.brightnessOf(context) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicator: const BubbleTabIndicator(),
                    tabs: const [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("常规"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("开关机计划管理"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("硬盘休眠"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("不断电系统"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: ListView(
                              children: [
                                MemoryCompressionCard(
                                  enableZram: enableZram.value,
                                  onToggle: (value) {
                                    enableZram.value = value;
                                  },
                                ),
                                PowerRecoveryCard(
                                  powerRecovery: powerRecovery.value,
                                  onRcPowerConfigChanged: (value) {
                                    setPowerRecovery('rc_power_config', value);
                                  },
                                  onWolChanged: (index, value) {
                                    setPowerRecovery('wol$index', value);
                                  },
                                ),
                                BeepControlCard(
                                  beepControl: beepControl.value,
                                  onBeepOptionChanged: (key, value) {
                                    setBeepControl(key, value);
                                  },
                                ),
                                FanModeCard(
                                  fanSpeed: fanSpeed.value,
                                  onFanModeChanged: (mode) {
                                    setFanSpeed('dual_fan_speed', mode);
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                LedBrightnessCard(
                                  led: led.value,
                                  onBrightnessChanged: (value) {
                                    setLed('led_brightness', value);
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  final apis = <Map<String, dynamic>>[
                                    {
                                      "api": "SYNO.Core.Hardware.ZRAM",
                                      "method": "set",
                                      "version": "1",
                                      "enable_zram": enableZram.value,
                                    },
                                    {
                                      "api": "SYNO.Core.Hardware.PowerRecovery",
                                      "method": "set",
                                      "version": "1",
                                      "rc_power_config":
                                          powerRecovery.value['rc_power_config'],
                                      "wol1": powerRecovery.value['wol1'] ?? false,
                                      "wol2": powerRecovery.value['wol2'] ?? false,
                                    },
                                    {
                                      "api": "SYNO.Core.Hardware.BeepControl",
                                      "method": "set",
                                      "version": "1",
                                      "fan_fail": beepControl.value['fan_fail'] ?? false,
                                      "volume_crash":
                                          beepControl.value['volume_crash'] ?? false,
                                      "ssd_cache_crash":
                                          beepControl.value['ssd_cache_crash'] ?? false,
                                      "poweron_beep":
                                          beepControl.value['poweron_beep'] ?? false,
                                      "poweroff_beep":
                                          beepControl.value['poweroff_beep'] ?? false,
                                    },
                                    {
                                      "api": "SYNO.Core.Hardware.FanSpeed",
                                      "method": "set",
                                      "version": "1",
                                      "dual_fan_speed":
                                          fanSpeed.value['dual_fan_speed'],
                                    },
                                    {
                                      "api": "SYNO.Core.Hardware.Led.Brightness",
                                      "method": "set",
                                      "version": "1",
                                      "led_brightness": led.value['led_brightness'],
                                      "schedule": led.value['schedule'],
                                    },
                                  ];
                                  final data = await dsmControlPanelPost({
                                    "stop_when_error": false,
                                    "api": 'SYNO.Entry.Request',
                                    "method": 'request',
                                    "mode": '"sequential"',
                                    "compound": jsonEncode(apis),
                                    "version": 1,
                                  });
                                  if (data['has_fail'] == false) {
                                    UiUtil.vibrate(FeedbackType.light);
                                    UiUtil.toast("保存成功");
                                  } else {
                                    UiUtil.vibrate(FeedbackType.warning);
                                    UiUtil.toast("设置未完全保存成功");
                                  }
                                  await getData();
                                } catch (e) {
                                  final code = e is DSMException ? e.code : -1;
                                  UiUtil.toast("保存失败,代码$code");
                                }
                              },
                              child: const Text(
                                ' 保存 ',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Expanded(
                            child: powerTasks.value.isNotEmpty
                                ? ListView.builder(
                                    itemBuilder: (context, i) {
                                      return PowerTaskItem(
                                        task: powerTasks.value[i],
                                        onEnabledChanged: (task) {
                                          task['enabled'] = !task['enabled'];
                                          powerTasks.value =
                                              List.of(powerTasks.value);
                                        },
                                        onRemove: (task) {
                                          powerTasks.value =
                                              List.of(powerTasks.value)
                                                ..remove(task);
                                        },
                                        onEdit: (task) {
                                          Navigator.of(context)
                                              .push(CupertinoPageRoute(
                                                  builder: (context) {
                                                    return AddPowerTask(
                                                      "编辑计划管理",
                                                      task: task,
                                                    );
                                                  },
                                                  settings: const RouteSettings(
                                                      name: "edit_power_task")))
                                              .then((value) {
                                            if (value != null) {
                                              for (var item in powerTasks.value) {
                                                if (item != task &&
                                                    item['hour'] ==
                                                        value['hour'] &&
                                                    item['min'] ==
                                                        value['min']) {
                                                  UiUtil.toast("无效或重复规则");
                                                  UiUtil.vibrate(
                                                      FeedbackType.warning);
                                                  return;
                                                }
                                              }
                                              task = value;
                                              powerTasks.value =
                                                  List.of(powerTasks.value);
                                            }
                                          });
                                        },
                                      );
                                    },
                                    itemCount: powerTasks.value.length,
                                  )
                                : Center(
                                    child: Text(
                                      "暂无开关机计划，请点击下方新增按钮添加",
                                      style: TextStyle(
                                          color: AppTheme.of(context)
                                              .placeholderColor),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      Navigator.of(context)
                                          .push(CupertinoPageRoute(
                                              builder: (context) {
                                                return const AddPowerTask(
                                                  "新增计划管理",
                                                );
                                              },
                                              settings: const RouteSettings(
                                                  name: "edit_power_task")))
                                          .then((value) {
                                        if (value != null) {
                                          for (var item in powerTasks.value) {
                                            if (item['hour'] == value['hour'] &&
                                                item['min'] == value['min']) {
                                              UiUtil.toast("无效或重复规则");
                                              UiUtil.vibrate(
                                                  FeedbackType.warning);
                                              return;
                                            }
                                          }
                                          powerTasks.value =
                                              List.of(powerTasks.value)
                                                ..add(value);
                                        }
                                      });
                                    },
                                    child: const Text(
                                      ' 新增 ',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      List powerOns = powerTasks.value
                                          .where((task) =>
                                              task['type'] == "power_on")
                                          .map((e) {
                                        e.remove("type");
                                        return e;
                                      }).toList();
                                      List powerOffs = powerTasks.value
                                          .where((task) =>
                                              task['type'] == "power_off")
                                          .map((e) {
                                        e.remove("type");
                                        return e;
                                      }).toList();
                                      try {
                                        await dsmControlPanelPost({
                                          "poweron_tasks": jsonEncode(powerOns),
                                          "poweroff_tasks": jsonEncode(powerOffs),
                                          "api": 'SYNO.Core.Hardware.PowerSchedule',
                                          "method": 'save',
                                          "version": 1,
                                        });
                                        UiUtil.toast("保存成功");
                                        await getData();
                                      } catch (e) {
                                        final code = e is DSMException ? e.code : -1;
                                        UiUtil.toast("保存失败,代码$code");
                                      }
                                    },
                                    child: const Text(
                                      ' 保存 ',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Expanded(
                            child: ListView(
                              children: [
                                HibernationSettingsCard(
                                  hibernation: hibernation.value,
                                  dataList: dataList,
                                  onIdleTimeChanged: (value) {
                                    setHibernation(
                                        {'internal_hd_idletime': value});
                                  },
                                  onDeepSleepChanged: (value) {
                                    setHibernation(
                                        {'sata_deep_sleep': value ? 1 : 0});
                                  },
                                ),
                                UsbHibernationCard(
                                  hibernation: hibernation.value,
                                  dataList: dataList,
                                  onUsbIdleTimeChanged: (value) {
                                    setHibernation({'usb_idletime': value});
                                  },
                                  onEnableLogChanged: (value) {
                                    setHibernation({'enable_log': value});
                                  },
                                ),
                                if (powerRecovery.value['wol1'] != null)
                                  AutoPowerOffCard(
                                    powerRecovery: powerRecovery.value,
                                    hibernation: hibernation.value,
                                    dataList: dataList,
                                    onAutoPowerOffEnableChanged: (value) {
                                      setHibernation({
                                        'auto_poweroff_enable': value,
                                        'auto_poweroff_time': 10,
                                      });
                                    },
                                    onAutoPowerOffTimeChanged: (value) {
                                      setHibernation(
                                          {'auto_poweroff_time': value});
                                    },
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await dsmControlPanelPost({
                                    "internal_hd_idletime":
                                        hibernation.value['internal_hd_idletime'],
                                    "sata_deep_sleep":
                                        hibernation.value['sata_deep_sleep'] == 1,
                                    "ignore_netbios_broadcast": false,
                                    "usb_idletime": hibernation.value['usb_idletime'],
                                    "enable_log": hibernation.value['enable_log'],
                                    "auto_poweroff_enable":
                                        hibernation.value['auto_poweroff_enable'],
                                    "auto_poweroff_time":
                                        hibernation.value['auto_poweroff_time'],
                                    "api": 'SYNO.Core.Hardware.Hibernation',
                                    "method": 'set',
                                    "version": 1,
                                  });
                                  UiUtil.toast("保存成功");
                                  await getData();
                                } catch (e) {
                                  final code = e is DSMException ? e.code : -1;
                                  UiUtil.toast("保存失败,代码$code");
                                }
                              },
                              child: const Text(
                                ' 保存 ',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Center(
                        child: Text("待开发"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
