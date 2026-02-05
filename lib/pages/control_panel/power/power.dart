import 'package:garden/pages/control_panel/power/add_power_task.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
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

class Power extends StatefulWidget {
  const Power({super.key});

  @override
  PowerState createState() => PowerState();
}

class PowerState extends State<Power> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  bool enableZram = false;
  Map powerRecovery = {};
  Map beepControl = {};
  Map fanSpeed = {};
  Map hibernation = {};
  Map ups = {};
  Map led = {};
  List powerTasks = [];

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
  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    Api.powerStatus().then((res) {
      if (res['success']) {
        setState(() {
          loading = false;
        });
        List result = res['data']['result'];
        for (var item in result) {
          if (item['success'] == true) {
            switch (item['api']) {
              case "SYNO.Core.Hardware.ZRAM":
                setState(() {
                  enableZram = item['data']['enable_zram'];
                });
                break;
              case "SYNO.Core.Hardware.PowerRecovery":
                setState(() {
                  powerRecovery = item['data'];
                });
                break;
              case "SYNO.Core.Hardware.BeepControl":
                setState(() {
                  beepControl = item['data'];
                });
                break;
              case "SYNO.Core.Hardware.FanSpeed":
                setState(() {
                  fanSpeed = item['data'];
                });
                break;
              case "SYNO.Core.Hardware.Led.Brightness":
                setState(() {
                  led = item['data'];
                });
                break;
              case "SYNO.Core.ExternalDevice.UPS":
                setState(() {
                  ups = item['data'];
                });
                break;
              case "SYNO.Core.Hardware.PowerSchedule":
                setState(() {
                  List powerOnTasks = item['data']['poweron_tasks'];
                  List powerOffTasks = item['data']['poweroff_tasks'];
                  powerTasks = powerOnTasks.map((e) {
                        e['type'] = "power_on";
                        return e;
                      }).toList() +
                      powerOffTasks.map((e) {
                        e['type'] = "power_off";
                        return e;
                      }).toList();
                  powerTasks.sort((a, b) {
                    if (a['hour'] > b['hour']) {
                      return 1;
                    } else if (a['hour'] == b['hour']) {
                      if (a['min'] > b['min']) {
                        return 1;
                      } else if (a['min'] < b['min']) {
                        return -1;
                      } else {
                        return 0;
                      }
                    } else {
                      return -1;
                    }
                  });
                });
                break;
              case "SYNO.Core.Hardware.Hibernation":
                setState(() {
                  hibernation = item['data'];
                });
                break;
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("硬件和电源"),
      ),
      body: loading
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
                    controller: _tabController,
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
                    controller: _tabController,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: ListView(
                              children: [
                                MemoryCompressionCard(
                                  enableZram: enableZram,
                                  onToggle: (value) {
                                    setState(() {
                                      enableZram = value;
                                    });
                                  },
                                ),
                                PowerRecoveryCard(
                                  powerRecovery: powerRecovery,
                                  onRcPowerConfigChanged: (value) {
                                    setState(() {
                                      powerRecovery['rc_power_config'] = value;
                                    });
                                  },
                                  onWolChanged: (index, value) {
                                    setState(() {
                                      powerRecovery['wol$index'] = value;
                                    });
                                  },
                                ),
                                BeepControlCard(
                                  beepControl: beepControl,
                                  onBeepOptionChanged: (key, value) {
                                    setState(() {
                                      beepControl[key] = value;
                                    });
                                  },
                                ),
                                FanModeCard(
                                  fanSpeed: fanSpeed,
                                  onFanModeChanged: (mode) {
                                    setState(() {
                                      fanSpeed['dual_fan_speed'] = mode;
                                    });
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                LedBrightnessCard(
                                  led: led,
                                  onBrightnessChanged: (value) {
                                    setState(() {
                                      led['led_brightness'] = value;
                                    });
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
                                var res = await Api.powerSet(enableZram,
                                    powerRecovery, beepControl, fanSpeed, led);
                                if (res['success']) {
                                  if (res['data']['has_fail'] == false) {
                                    UiUtil.vibrate(FeedbackType.light);
                                    UiUtil.toast("保存成功");
                                  } else {
                                    UiUtil.vibrate(FeedbackType.warning);
                                    UiUtil.toast("设置未完全保存成功");
                                  }
                                  getData();
                                } else {
                                  HttpUtil.instance
                                      .toast("保存失败,代码${res['error']['code']}");
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
                            child: powerTasks.isNotEmpty
                                ? ListView.builder(
                                    itemBuilder: (context, i) {
                                      return PowerTaskItem(
                                        task: powerTasks[i],
                                        onEnabledChanged: (task) {
                                          setState(() {
                                            task['enabled'] = !task['enabled'];
                                          });
                                        },
                                        onRemove: (task) {
                                          setState(() {
                                            powerTasks.remove(task);
                                          });
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
                                              for (var item in powerTasks) {
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
                                              setState(() {
                                                task = value;
                                              });
                                            }
                                          });
                                        },
                                      );
                                    },
                                    itemCount: powerTasks.length,
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
                                          for (var item in powerTasks) {
                                            if (item['hour'] == value['hour'] &&
                                                item['min'] == value['min']) {
                                              UiUtil.toast("无效或重复规则");
                                              UiUtil.vibrate(
                                                  FeedbackType.warning);
                                              return;
                                            }
                                          }
                                          setState(() {
                                            powerTasks.add(value);
                                          });
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
                                      List powerOns = powerTasks
                                          .where((task) =>
                                              task['type'] == "power_on")
                                          .map((e) {
                                        e.remove("type");
                                        return e;
                                      }).toList();
                                      List powerOffs = powerTasks
                                          .where((task) =>
                                              task['type'] == "power_off")
                                          .map((e) {
                                        e.remove("type");
                                        return e;
                                      }).toList();
                                      var res = await Api.powerScheduleSave(
                                          powerOns, powerOffs);
                                      if (res['success']) {
                                        UiUtil.toast("保存成功");
                                        getData();
                                      } else {
                                        UiUtil.toast(
                                            "保存失败,代码${res['error']['code']}");
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
                                  hibernation: hibernation,
                                  dataList: dataList,
                                  onIdleTimeChanged: (value) {
                                    setState(() {
                                      hibernation['internal_hd_idletime'] =
                                          value;
                                    });
                                  },
                                  onDeepSleepChanged: (value) {
                                    setState(() {
                                      hibernation['sata_deep_sleep'] =
                                          value ? 1 : 0;
                                    });
                                  },
                                ),
                                UsbHibernationCard(
                                  hibernation: hibernation,
                                  dataList: dataList,
                                  onUsbIdleTimeChanged: (value) {
                                    setState(() {
                                      hibernation['usb_idletime'] = value;
                                    });
                                  },
                                  onEnableLogChanged: (value) {
                                    setState(() {
                                      hibernation['enable_log'] = value;
                                    });
                                  },
                                ),
                                if (powerRecovery['wol1'] != null)
                                  AutoPowerOffCard(
                                    powerRecovery: powerRecovery,
                                    hibernation: hibernation,
                                    dataList: dataList,
                                    onAutoPowerOffEnableChanged: (value) {
                                      setState(() {
                                        hibernation['auto_poweroff_enable'] =
                                            value;
                                        hibernation['auto_poweroff_time'] = 10;
                                      });
                                    },
                                    onAutoPowerOffTimeChanged: (value) {
                                      setState(() {
                                        hibernation['auto_poweroff_time'] =
                                            value;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: OutlinedButton(
                              onPressed: () async {
                                var res = await Api.powerHibernationSave(
                                  internalHdIdletime:
                                      hibernation['internal_hd_idletime'],
                                  sataDeepSleep:
                                      hibernation['sata_deep_sleep'] == 1,
                                  usbIdletime: hibernation['usb_idletime'],
                                  enableLog: hibernation['enable_log'],
                                  autoPoweroffEnable:
                                      hibernation['auto_poweroff_enable'],
                                  autoPoweroffTime:
                                      hibernation['auto_poweroff_time'],
                                );
                                if (res['success']) {
                                  UiUtil.toast("保存成功");
                                  getData();
                                } else {
                                  HttpUtil.instance
                                      .toast("保存失败,代码${res['error']['code']}");
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
