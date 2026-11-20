import 'package:garden/pages/resource_monitor/performance.dart';
import 'package:garden/pages/resource_monitor/task_manager.dart';
import 'package:garden/pages/resource_monitor/users.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ResourceMonitor extends StatelessWidget {
  const ResourceMonitor({super.key, this.tabIndex = 0});
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("资源监控"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return const Performance();
                    },
                    settings: const RouteSettings(name: "performance"),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Image.asset(
                      "assets/control_panel/performance.png",
                      width: 40,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Expanded(
                      child: Text(
                        "性能",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return const TaskManager();
                    },
                    settings: const RouteSettings(name: "task_manager"),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Image.asset(
                      "assets/control_panel/task_manager.png",
                      width: 40,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Expanded(
                      child: Text(
                        "任务管理器",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return const Users();
                    },
                    settings: const RouteSettings(name: "monitor_users"),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Image.asset(
                      "assets/control_panel/plugin.png",
                      width: 40,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Expanded(
                      child: Text(
                        "目前连接用户",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
          //   child: NeuButton(
          //     onPressed: () {
          //       Navigator.of(context).push(
          //         CupertinoPageRoute(
          //           builder: (context) {
          //             return SpeedLimit();
          //           },
          //           settings: RouteSettings(name: "speed_limit"),
          //         ),
          //       );
          //     },
          //     padding: EdgeInsets.zero,
          //     decoration: NeumorphicDecoration(
          //       color: Theme.of(context).scaffoldBackgroundColor,
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     bevel: 20,
          //     child: Padding(
          //       padding: EdgeInsets.symmetric(vertical: 20),
          //       child: Row(
          //         children: [
          //           SizedBox(
          //             width: 20,
          //           ),
          //           Image.asset(
          //             "assets/control_panel/speed.png",
          //             width: 40,
          //           ),
          //           SizedBox(
          //             width: 10,
          //           ),
          //           Expanded(
          //             child: Text(
          //               "速度限制",
          //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          //             ),
          //           ),
          //           SizedBox(
          //             width: 20,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          // Padding(
          //   padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
          //   child: NeuButton(
          //     onPressed: () {
          //       Navigator.of(context).push(
          //         CupertinoPageRoute(
          //           builder: (context) {
          //             return MonitorSetting();
          //           },
          //           settings: RouteSettings(name: "monitor_setting"),
          //         ),
          //       );
          //     },
          //     padding: EdgeInsets.zero,
          //     decoration: NeumorphicDecoration(
          //       color: Theme.of(context).scaffoldBackgroundColor,
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     bevel: 20,
          //     child: Padding(
          //       padding: EdgeInsets.symmetric(vertical: 20),
          //       child: Row(
          //         children: [
          //           SizedBox(
          //             width: 20,
          //           ),
          //           Image.asset(
          //             "assets/icons/setting.png",
          //             width: 40,
          //           ),
          //           SizedBox(
          //             width: 10,
          //           ),
          //           Expanded(
          //             child: Text(
          //               "设置",gg
          //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          //             ),
          //           ),
          //           SizedBox(
          //             width: 20,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
