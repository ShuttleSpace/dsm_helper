import 'dart:convert';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/extensions/list.dart';
import 'package:garden/pages/packages/detail.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/packages/package_card.dart';
import 'package:garden/widgets/packages/update_package_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

/* {
  "auto_upgrade_from": null,
  "beta": false,
  "breakpkgs": null,
  "category": 0,
  "changelog": "Update to v0.107.65，初始化后重启套件会自动同步端口。",
  "conflictpkgs": null,
  "deppkgs": null,
  "depsers": null,
  "desc": "AdGuard Home 是一款全网范围的广告拦截和追踪软件。设置好之后，它将覆盖你所有的家庭设备，你不需要任何客户端软件。⚠️本套件将以root权限运行！",
  "distributor": "矿神SPK7",
  "distributor_url": "http://spk7.imnks.com/",
  "dname": "AdGuard Home",
  "download_count": 2026,
  "id": "AdGuardHome",
  "link": "https://spk7.imnks.com/packages2025/AdGuardHome-v0.107.65-x86_64-DSM7.spk",
  "maintainer": "AdguardTeam",
  "maintainer_url": "https://github.com/AdguardTeam/AdGuardHome",
  "md5": "230c18b95bd3b03f57723eea1bfde954",
  "package": "AdGuardHome",
  "price": 0,
  "qinst": false,
  "qstart": false,
  "qupgrade": false,
  "recent_download_count": 0,
  "replaceforcepkgs": null,
  "replacepkgs": null,
  "silent_install": false,
  "silent_uninstall": false,
  "silent_upgrade": false,
  "size": 11376640,
  "snapshot": [],
  "source": "others",
  "start": true,
  "subcategory": 0,
  "support_url": "",
  "thirdparty": true,
  "thumbnail": [
    "https://spk7.imnks.com/cache/AdGuardHome-v0.107.65-x86_64-DSM7_thumb_72.png",
    "https://spk7.imnks.com/cache/AdGuardHome-v0.107.65-x86_64-DSM7_thumb_120.png"
  ],
  "type": 0,
  "version": "0.107.65"
} */

class Packages extends StatefulWidget {
  final String version;
  const Packages(this.version, {super.key});
  @override
  PackagesState createState() => PackagesState();
}

class PackagesState extends State<Packages>
    with TickerProviderStateMixin, SignalsMixin {
  int packagesVersion = 1;
  int installedVersion = 1;
  late TabController _tabController;

  late final _others = createListSignal([]);
  late final filteredOthers = createComputed(() {
    if (searchKeyword.value.isEmpty) return _others;
    return _others.filter((v) =>
        v['dname']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()) ||
        v['desc']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()));
  });

  late final _packages = createListSignal([]);
  late final filteredPackages = createComputed(() {
    if (searchKeyword.value.isEmpty) return _packages;
    return _packages.filter((v) =>
        v['dname']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()) ||
        v['desc']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()));
  });
  late final _betas = createListSignal([]);
  late final filteredBetas = createComputed(() {
    if (searchKeyword.value.isEmpty) return _betas;
    return _betas.filter((v) =>
        v['dname']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()) ||
        v['desc']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()));
  });

  late final categories = createListSignal<Map>([]);
  late final _installedPackages = createListSignal([]);
  late final filteredinstalledPackages = createComputed(() {
    if (searchKeyword.value.isEmpty) return _installedPackages;
    return _installedPackages.filter((v) =>
        v['dname']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()) ||
        v['desc']
            .toString()
            .toLowerCase()
            .contains(searchKeyword.value.toLowerCase()));
  });

  late final canUpdatePackages = createListSignal([]);
  late final launchedPackages = createListSignal([]);

  late final installedPackagesInfo = createListSignal([]);

  late final volumes = createListSignal([]);
  late final loading = createSignal(false);
  late final loadingAll = createSignal(false);
  late final loadingInstalled = createSignal(true);
  late final loadingOthers = createSignal(true);

  late final useGridLayout = createSignal(false);
  late final showSearchBar = createSignal(false);
  late final searchController = TextEditingController();
  late final searchKeyword = createSignal('');

  @override
  void initState() {
    searchController.addListener(() {
      searchKeyword.value = searchController.text;
    });
    _tabController = TabController(initialIndex: 1, length: 3, vsync: this);
    _parseVersion();
    _fetchData();
    super.initState();
  }

  @override
  dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  _parseVersion() {
    String ver = widget.version;
    int end = ver.indexOf("-");
    final dsmVersion = ver.substring(4, end);
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
  }

  _fetchData() async {
    try {
      loadingAll.value = true;
      final res = await dsmCorePackageServerList(version: packagesVersion);
      if (res['packages'] != null) {
        _packages.value = res['packages'];
      } else {
        // fixme: res['data']
        _packages.value = [];
      }
      if (res['beta_packages'] != null) {
        _betas.value = res['beta_packages'];
        if (_betas.isNotEmpty) {
          _tabController =
              TabController(initialIndex: 1, length: 4, vsync: this);
        }
      }
      categories.value = res['categories'] ?? [];
    } on Exception catch (e) {
      Log.error(e);
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
      return;
    }
    loadingAll.value = false;
    _fetchThird();
    _fetchLaunchedPackages();
    _fetchInstalledPackages();
    _fetchVolumes();
  }

  _fetchVolumes() async {
    try {
      final res = await dsmCoreStorageVolumeList();
      volumes.value = res['volumes'] ?? [];
    } on Exception catch (e) {
      Log.error(e);
    }
  }

  _fetchThird() async {
    try {
      final res = await dsmCorePackageServerList(
          blloadothers: true, version: packagesVersion);
      if (res['packages'] != null) {
        _others.value = res['packages'] ?? [];
      } else {
        // fixme: res['data']
        _others.value = [];
      }
    } on Exception catch (e) {
      Log.error(e);
      _fixAll();
    }
    loadingOthers.value = false;
  }

  _fetchLaunchedPackages() async {
    launchedPackages.clear();
    try {
      final res = await dsmCorePollingData();
      Map packages = res['packages'] ?? {};
      packages.forEach((key, value) {
        launchedPackages.add(key);
      });
      _fixAll();
    } on Exception catch (e) {
      Log.error(e);
    }
  }

  _fetchInstalledPackages() async {
    _installedPackages.clear();
    List<String> additional = [
      "description",
      "description_enu",
      "beta",
      "distributor",
      "distributor_url",
      "maintainer",
      "maintainer_url",
      "dsm_apps",
      "report_beta_url",
      "support_center",
      "startable",
      "installed_info",
      "support_url",
      "is_uninstall_pages",
      "install_type",
      "autoupdate",
      "silent_upgrade",
      "installing_progress",
      "ctl_uninstall",
      "status",
      "url",
    ];
    if (installedVersion == 2) {
      additional.add("updated_at");
    }
    try {
      final res = await dsmCorePackageList(
          additional: jsonEncode(additional),
          pollingInterval: 15,
          version: installedVersion);
      installedPackagesInfo.value = res['packages'];
      loadingInstalled.value = false;
      _fixAll();
    } on Exception catch (e) {
      Log.error(e);
    }
  }

  _fixAll() {
    _fixPackage(_packages);
    _fixPackage(_others);
    _fixPackage(_betas);
  }

  _fixPackage(ListSignal target) {
    final tmp = target.value;
    for (final package in tmp) {
      package['installed'] = package['installed'] ?? false;
      package['installed_version'] = package['installed_version'] ?? "";
      package['can_update'] = package['can_update'] ?? false;
      package['launched'] = package['launched'] ?? false;
      final info = installedPackagesInfo
          .filter((v) => v['id'] == package['id'])
          .firstOrNull;
      if (info != null) {
        package['installed'] = true;
        package['installed_version'] = info['version'];
        package['can_update'] =
            versionCompare(package['installed_version'], package['version']) <
                0;
        package['additional'] = info['additional'];
        if (package['installed']) {
          final idx =
              _installedPackages.indexWhere((t) => t['id'] == package['id']);
          if (idx != -1) {
            _installedPackages.replaceRange(idx, idx + 1, package);
          } else {
            _installedPackages.add(package);
          }
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
    }
    target.value = tmp;
  }

  List<String> getCategoryName(List categoryIds) {
    List<String> name = [];
    for (int i = 0; i < categoryIds.length; i++) {
      for (final category in categories) {
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
      await _fetchInstalledPackages();
      loading.value = false;
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
      await _fetchInstalledPackages();
      loading.value = false;
    });
  }

  // 处理启动套件
  Future<void> _handleStartPackage(Map package) async {
    loading.value = true;
    try {
      await dsmCorePackageControlStart(
          package['id'], jsonEncode(package['dsm_apps']));
      UiUtil.toast("已启动");
      await _fetchInstalledPackages();
      loading.value = false;
    } on Exception catch (e) {
      Log.error(e);
    }
  }

  // 处理停止套件
  Future<void> _handleStopPackage(Map package) async {
    loading.value = true;
    try {
      await dsmCorePackageControlStop(package['id']);
      UiUtil.toast("已停用");
      // await getLaunchedPackages();
      await _fetchInstalledPackages();
      loading.value = false;
    } on Exception catch (e) {
      Log.error(e);
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
          await _fetchInstalledPackages();
          loading.value = false;
        });
      },
      onUpdate: () => _handleUpdatePackage(update),
      onInstall: () => _handleInstallPackage(update),
      onStart: () => _handleStartPackage(update),
      onStop: () => _handleStopPackage(update),
    );
  }

  Widget _buildPackageItem(package, bool installed,
      {bool isBeta = false, bool horizontal = false}) {
    return PackageCard(
      package: package,
      installed: installed,
      isBeta: isBeta,
      horizontal: horizontal,
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
          await _fetchInstalledPackages();
          loading.value = false;
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
        actions: [
          Builder(builder: (context) {
            if (showSearchBar.watch(context)) {
              return SizedBox(
                width: MediaQuery.sizeOf(context).width / 3,
                child: TextField(
                  controller: searchController,
                ),
              );
            }
            return IconButton(
                onPressed: () {
                  showSearchBar.value = true;
                },
                icon: const Icon(Icons.search));
          }),
          Tooltip(
            message: '点击切换布局',
            child: IconButton(
                onPressed: () {
                  useGridLayout.value = !useGridLayout.value;
                },
                icon: useGridLayout.watch(context)
                    ? const Icon(Icons.grid_view_outlined)
                    : const Icon(Icons.view_list_outlined)),
          ),
          const SizedBox(
            width: 15,
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Card(
                shape: context.roundRectShapeBorder,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: TabBar(
                  dividerHeight: 0,
                  isScrollable: true,
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.label,
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
                    if (_betas.isNotEmpty)
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
                    Builder(builder: (context) {
                      if (loadingInstalled.watch(context)) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        );
                      } else {
                        if (useGridLayout.watch(context)) {
                          return GridView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3),
                            children: [
                              if (canUpdatePackages.isNotEmpty)
                                ListView.builder(
                                  itemBuilder: (content, i) {
                                    return _buildUpdateItem(
                                        canUpdatePackages[i]);
                                  },
                                  itemCount: canUpdatePackages.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                ),
                              ...filteredinstalledPackages.map((package) {
                                return _buildPackageItem(package, true);
                              })
                            ],
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          children: [
                            if (canUpdatePackages.isNotEmpty)
                              ListView.builder(
                                itemBuilder: (content, i) {
                                  return _buildUpdateItem(canUpdatePackages[i]);
                                },
                                itemCount: canUpdatePackages.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                              ),
                            Wrap(
                              runSpacing: 20,
                              spacing: 20,
                              children:
                                  filteredinstalledPackages.map((package) {
                                return _buildPackageItem(package, true,
                                    horizontal: true);
                              }).toList(),
                            ),
                          ],
                        );
                      }
                    }),
                    Builder(builder: (context) {
                      if (loadingAll.watch(context)) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        );
                      } else {
                        if (useGridLayout.watch(context)) {
                          return GridView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3),
                            children: filteredPackages.map((package) {
                              return _buildPackageItem(package, false);
                            }).toList(),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          children: filteredPackages.map((package) {
                            return _buildPackageItem(package, false,
                                horizontal: true);
                          }).toList(),
                        );
                      }
                    }),
                    Builder(builder: (context) {
                      if (loadingOthers.watch(context)) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        );
                      } else {
                        if (useGridLayout.watch(context)) {
                          return GridView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3),
                            children: filteredOthers.map((package) {
                              return _buildPackageItem(package, false);
                            }).toList(),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          children: filteredOthers.map((package) {
                            return _buildPackageItem(package, false,
                                horizontal: true);
                          }).toList(),
                        );
                      }
                    }),
                    if (filteredBetas.watch(context).isNotEmpty)
                      ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        children: [
                          Wrap(
                            runSpacing: 20,
                            spacing: 20,
                            children: filteredBetas.map((package) {
                              return _buildPackageItem(package, false,
                                  isBeta: true, horizontal: true);
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (loading.watch(context))
            Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: .4),
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
