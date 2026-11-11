import 'package:garden/pages/docker/detail.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/action_dialog.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/docker/container_item.dart';
import 'package:garden/widgets/docker/image_item.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Docker extends HookWidget {
  final String title;
  const Docker({super.key, this.title = 'Docker'});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 3, vsync: tickerProvider),
      const [],
    );
    final containers = useSignal<List>([]);
    final images = useSignal<List>([]);
    final registries = useSignal<List>([]);
    final powerLoading = useSignal<Map>({});
    final utilization = useSignal<Map>({});
    final containerLoading = useSignal(true);
    final imageLoading = useSignal(true);

    getContainer() async {
      var res = await DsmApi.dockerContainerInfo();
      containerLoading.value = false;
      if (res['success']) {
        List result = res['data']['result'];
        for (var item in result) {
          if (item['success'] == true) {
            switch (item['api']) {
              case "SYNO.Core.System.Utilization":
                utilization.value = item['data'];
                break;
              case "SYNO.Docker.Container":
                containers.value = item['data']['containers'];
                containers.value.sort((a, b) {
                  return a['name'].compareTo(b['name']);
                });
                break;
              case "SYNO.Docker.Container.Resource":
                List resources = item['data']['resources'];
                for (var resource in resources) {
                  for (var container in containers.value) {
                    if (resource['name'] == container['name']) {
                      container['cpu'] = resource['cpu'];
                      container['memory'] = resource['memory'];
                      container['memoryPercent'] = resource['memoryPercent'];
                    }
                  }
                }
                containers.value = List.of(containers.value);
                break;
            }
          }
        }
      }
    }

    getImage() async {
      var res = await DsmApi.dockerImageInfo();
      Log.info(res);
      imageLoading.value = false;
      if (res['success']) {
        List result = res['data']['result'];
        for (var item in result) {
          if (item['success'] == true) {
            switch (item['api']) {
              case "SYNO.Docker.Image":
                images.value = item['data']['images'];
                images.value.sort((a, b) {
                  return a['repository'].compareTo(b['repository']);
                });
                break;
              case "SYNO.Docker.Registry":
                registries.value = item['data']['registries'];
                break;
            }
          }
        }
      }
    }

    power(container, String action, {bool preserveProfile = false}) async {
      if (action == "signal" || action == "delete") {
        final message = action == "signal"
            ? "是否确定要强制停止容器？所有未保存的数据将丢失！"
            : preserveProfile
                ? "容器 ${container['name']} 将被清除。清除后，容器中的所有数据将丢失。是否确定继续？"
                : "容器 ${container['name']} 将被删除。删除后，容器中的所有数据将丢失。是否确定继续？";

        final confirmed = await ActionDialog.show(
          context: context,
          title: "确认操作",
          message: message,
          confirmText: "确认",
          isDanger: true,
        );

        if (confirmed == true) {
          powerLoading.value = {
            ...powerLoading.value,
            container['id']: true
          };
          var res = await DsmApi.dockerPower(container['name'], action,
              preserveProfile: preserveProfile);
          if (res['success']) {
            UiUtil.toast("请求发送成功");
            getContainer();
          } else {
            UiUtil.toast("请求发送失败，代码：${res['error']['code']}");
          }
          powerLoading.value = {
            ...powerLoading.value,
            container['id']: false
          };
        }
      } else {
        powerLoading.value = {...powerLoading.value, container['id']: true};
        var res = await DsmApi.dockerPower(container['name'], action);
        if (res['success']) {
          UiUtil.toast("请求发送成功");
          getContainer();
        } else {
          UiUtil.toast("请求发送失败，代码：${res['error']['code']}");
        }
        powerLoading.value = {...powerLoading.value, container['id']: false};
      }
    }

    useEffect(() {
      getContainer();
      getImage();
      return () {
        tabController.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title),
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: TabBar(
              dividerHeight: 0,
              isScrollable: false,
              controller: tabController,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.brightnessOf(context) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: const BubbleTabIndicator(),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("容器"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("镜像"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("注册表"),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                containerLoading.value
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingLarge),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              "assets/icons/cpu.png",
                                              width: 50,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Text(
                                              "CPU",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        FAProgressBar(
                                          backgroundColor: Colors.transparent,
                                          changeColorValue: 90,
                                          changeProgressColor: Colors.red,
                                          progressColor: Colors.blue,
                                          currentValue: utilization.value['cpu']
                                                  ['user_load'] +
                                              utilization.value['cpu']
                                                  ['system_load'],
                                          displayText: '%',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              "assets/icons/ram.png",
                                              width: 50,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Text(
                                              "内存",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        FAProgressBar(
                                          backgroundColor: Colors.transparent,
                                          changeColorValue: 90,
                                          changeProgressColor: Colors.red,
                                          progressColor: Colors.blue,
                                          currentValue: utilization
                                              .value['memory']['real_usage'],
                                          displayText: '%',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ...containers.value.map((container) => ContainerItem(
                                container: container,
                                isLoading:
                                    powerLoading.value[container['id']] ??
                                        false,
                                onTap: () {
                                  Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (context) {
                                        return ContainerDetail(
                                            container['name']);
                                      },
                                      settings: const RouteSettings(
                                          name: "docker_container_detail")));
                                },
                                onAction: (action,
                                    {bool preserveProfile = false}) {
                                  power(container, action,
                                      preserveProfile: preserveProfile);
                                },
                              )),
                        ],
                      ),
                imageLoading.value
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return ImageItem(image: images.value[i]);
                        },
                        separatorBuilder: (context, i) {
                          return const SizedBox(
                            height: 20,
                          );
                        },
                        itemCount: images.value.length),
                const Center(
                  child: Text("开发中"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
