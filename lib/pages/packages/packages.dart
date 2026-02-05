import 'package:garden/pages/packages/detail.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/packages/package_card.dart';
import 'package:garden/widgets/packages/update_package_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Packages extends StatefulWidget {
  final String version;
  const Packages(this.version, {super.key});
  @override
  PackagesState createState() => PackagesState();
}

class PackagesState extends State<Packages> with TickerProviderStateMixin {
  int packagesVersion = 1;
  int installedVersion = 1;
  late TabController _tabController;
  List banners = [];
  List others = [];
  List packages = [];
  List betas = [];

  List categories = [];
  List installedPackages = [];
  List canUpdatePackages = [];
  List launchedPackages = [];

  List installedPackagesInfo = [];

  List volumes = [];
  bool loading = false;
  bool loadingAll = true;
  bool loadingInstalled = true;
  bool loadingOthers = true;
  List get allPackages {
    return packages + betas + others;
  }

  @override
  void initState() {
    String ver = widget.version;
    int end = ver.indexOf("-");
    var dsmVersion = ver.substring(4, end);
    List v = dsmVersion.split(".");
    if (v[0] == "6" && v[1] == "1") {
      installedVersion = 1;
      packagesVersion = 1;
    } else if (v[0] == "5") {
      packagesVersion = 1;
      installedVersion = 1;
    } else if (v[0] == "6" && v[1] == "2" && v.length == 2) {
      installedVersion = 1;
      packagesVersion = 2;
    } else {
      packagesVersion = 2;
      installedVersion = 2;
    }
    _tabController = TabController(initialIndex: 1, length: 3, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    var res = await Api.packages(version: packagesVersion);
    if (res['success']) {
      setState(() {
        banners = res['data']['banners'];
        if (res['data']['packages'] != null) {
          packages = res['data']['packages'];
        } else {
          packages = res['data']['data'];
        }
        if (res['data']['beta_packages'] != null) {
          betas = res['data']['beta_packages'];
          if (betas.isNotEmpty) {
            _tabController =
                TabController(initialIndex: 1, length: 4, vsync: this);
          }
        }
        //
        categories = res['data']['categories'];
      });
      setState(() {
        loadingAll = false;
      });
    } else {
      UiUtil.toast("数据加载失败");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
      return;
    }
    getOthers();
    // getLaunchedPackages();
    getInstalledPackages();
    getVolumes();
  }

  getVolumes() async {
    var res = await Api.volumes();
    if (res['success']) {
      setState(() {
        volumes = res['data']['volumes'];
      });
    }
  }

  getOthers() async {
    Log.info("获取第三方套件");
    var res = await Api.packages(others: true, version: packagesVersion);
    Log.info("获取第三方套件end");
    if (res['success']) {
      setState(() {
        if (res['data']['packages'] != null) {
          others = res['data']['packages'];
        } else {
          others = res['data']['data'];
        }
        //
        loadingOthers = false;
      });
      calcInstalledPackage();
    }
  }

  // getLaunchedPackages() async {
  //   return;
  //   launchedPackages = [];
  //   Log.info("获取运行中套件");
  //   var res = await Api.launchedPackages();
  //   Log.info(res);
  //   Log.info("获取运行中套件end");
  //   if (res['success']) {
  //     Map packages = res['data']['packages'];
  //     packages.forEach((key, value) {
  //       launchedPackages.add(key);
  //       setState(() {});
  //     });
  //     calcInstalledPackage();
  //   }
  // }

  getInstalledPackages() async {
    installedPackages = [];

    Log.info("获取已安装套件");
    var res = await Api.installedPackages(version: installedVersion);
    Log.info("获取已安装套件end");
    if (res['success']) {
      setState(() {
        installedPackagesInfo = res['data']['packages'];
        loadingInstalled = false;
      });
      calcInstalledPackage();
    } else {
      Log.info(res);
      Log.info("获取已安装套件失败");
    }
  }

  calcInstalledPackage() {
    canUpdatePackages = [];
    for (var installedPackageInfo in installedPackagesInfo) {
      for (var package in allPackages) {
        package['installed'] = package['installed'] ?? false;
        package['installed_version'] = package['installed_version'] ?? "";
        package['can_update'] = package['can_update'] ?? false;
        package['launched'] = package['launched'] ?? false;
        if (installedPackageInfo['id'] == package['id']) {
          package['installed'] = true;
          package['installed_version'] = installedPackageInfo['version'];
          package['can_update'] = HttpUtil.instance.versionCompare(
                  package['installed_version'], package['version']) <
              0;
          package['additional'] = installedPackageInfo['additional'];
          if (package['installed']) {
            installedPackages.add(package);
          }
          if (package['can_update']) {
            canUpdatePackages.add(package);
          }
          if (package['additional'] != null &&
              package['additional']['status'] == "running") {
            package['launched'] = true;
          } else if (launchedPackages.contains(package['id'])) {
            package['launched'] = true;
          }
        }
        setState(() {});
      }
    }
  }

  List<String> getCategoryName(List categoryIds) {
    List<String> name = [];
    for (int i = 0; i < categoryIds.length; i++) {
      for (var category in categories) {
        if (category['id'] == categoryIds[i]) {
          name.add(category['dname']);
        }
      }
    }
    return name;
  }

  // 处理更新套件
  Future<void> _handleUpdatePackage(Map package, {bool beta = false}) async {
    Navigator.of(context)
        .push(CupertinoPageRoute(
            builder: (context) {
              return PackageDetail(package, beta: beta, method: "update");
            },
            settings: const RouteSettings(name: "package_detail")))
        .then((_) async {
      // await getLaunchedPackages();
      await getInstalledPackages();
      setState(() {
        loading = false;
      });
    });
  }

  // 处理安装套件
  Future<void> _handleInstallPackage(Map package, {bool beta = false}) async {
    Navigator.of(context)
        .push(CupertinoPageRoute(
            builder: (context) {
              return PackageDetail(package, beta: beta, method: "install");
            },
            settings: const RouteSettings(name: "package_detail")))
        .then((_) async {
      // await getLaunchedPackages();
      await getInstalledPackages();
      setState(() {
        loading = false;
      });
    });
  }

  // 处理启动套件
  Future<void> _handleStartPackage(Map package) async {
    setState(() {
      loading = true;
    });
    var res =
        await Api.launchPackage(package['id'], package['dsm_apps'], "start");
    if (res['success']) {
      UiUtil.toast("已启动");
      // await getLaunchedPackages();
      await getInstalledPackages();
      setState(() {
        loading = false;
      });
    }
  }

  // 处理停止套件
  Future<void> _handleStopPackage(Map package) async {
    setState(() {
      loading = true;
    });
    var res =
        await Api.launchPackage(package['id'], package['dsm_apps'], "stop");
    if (res['success']) {
      UiUtil.toast("已停用");
      // await getLaunchedPackages();
      await getInstalledPackages();
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildUpdateItem(update) {
    return UpdatePackageItem(
      update: update,
      onTap: () {
        Navigator.of(context)
            .push(CupertinoPageRoute(
                builder: (context) {
                  return PackageDetail(update);
                },
                settings: const RouteSettings(name: "package_detail")))
            .then((_) async {
          // await getLaunchedPackages();
          await getInstalledPackages();
          setState(() {
            loading = false;
          });
        });
      },
      onUpdate: () => _handleUpdatePackage(update),
      onInstall: () => _handleInstallPackage(update),
      onStart: () => _handleStartPackage(update),
      onStop: () => _handleStopPackage(update),
    );
  }

  Widget _buildPackageItem(package, bool installed, {bool isBeta = false}) {
    return PackageCard(
      package: package,
      installed: installed,
      isBeta: isBeta,
      getCategoryName: getCategoryName,
      onTap: () {
        Navigator.of(context)
            .push(CupertinoPageRoute(
                builder: (context) {
                  return PackageDetail(package, beta: isBeta);
                },
                settings: const RouteSettings(name: "package_detail")))
            .then((_) async {
          // await getLaunchedPackages();
          await getInstalledPackages();
          setState(() {
            loading = false;
          });
        });
      },
      onUpdate: () => _handleUpdatePackage(package, beta: isBeta),
      onInstall: () => _handleInstallPackage(package, beta: isBeta),
      onStart: () => _handleStartPackage(package),
      onStop: () => _handleStopPackage(package),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "套件中心",
        ),
      ),
      body: Stack(
        children: [
          Column(
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
                  indicator: BubbleTabIndicator(
                    indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                    shadowColor: HttpUtil.getAdjustColor(
                        Theme.of(context).scaffoldBackgroundColor, -20),
                  ),
                  tabs: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Text("已安装"),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Text("全部套件"),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Text("社群"),
                    ),
                    if (betas.isNotEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("Beta"),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Container(
                      child: loadingInstalled
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              children: [
                                if (canUpdatePackages.isNotEmpty)
                                  ListView.builder(
                                    itemBuilder: (content, i) {
                                      return _buildUpdateItem(
                                          canUpdatePackages[i]);
                                    },
                                    itemCount: canUpdatePackages.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                  ),
                                Wrap(
                                  runSpacing: 20,
                                  spacing: 20,
                                  children: installedPackages.map((package) {
                                    return _buildPackageItem(package, true);
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                    Container(
                      child: loadingAll
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              children: [
                                Wrap(
                                  runSpacing: 20,
                                  spacing: 20,
                                  children: packages.map((package) {
                                    return _buildPackageItem(package, false);
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                    Container(
                      child: loadingOthers
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              children: [
                                Wrap(
                                  runSpacing: 20,
                                  spacing: 20,
                                  children: others.map((package) {
                                    return _buildPackageItem(package, false);
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                    if (betas.isNotEmpty)
                      ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        children: [
                          Wrap(
                            runSpacing: 20,
                            spacing: 20,
                            children: betas.map((package) {
                              return _buildPackageItem(package, false,
                                  isBeta: true);
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (loading)
            Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: .7),
              child: const Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
