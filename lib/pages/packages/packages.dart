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
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Packages extends HookWidget {
  final String version;
  const Packages(this.version, {super.key});

  @override
  Widget build(BuildContext context) {
    final packagesVersion = useRef(1);
    final installedVersion = useRef(1);
    final tickerProvider = useMemoized(() => _PackageTickerProvider(), const []);
    final others = useListSignal([]);
    final packages = useListSignal([]);
    final betas = useListSignal([]);
    final categories = useListSignal<Map>([]);
    final installedPackages = useListSignal([]);
    final canUpdatePackages = useListSignal([]);
    final launchedPackages = useListSignal([]);
    final installedPackagesInfo = useListSignal([]);
    final volumes = useListSignal([]);
    final loading = useSignal(false);
    final loadingAll = useSignal(false);
    final loadingInstalled = useSignal(true);
    final loadingOthers = useSignal(true);
    final useGridLayout = useSignal(false);
    final showSearchBar = useSignal(false);
    final searchController = useTextEditingController();
    final searchKeyword = useSignal('');

    final tabLength = betas.isNotEmpty ? 4 : 3;
    final tabController = useMemoized(
      () => TabController(initialIndex: 1, length: tabLength,
          vsync: tickerProvider),
      [tabLength],
    );

    final filteredOthers = useComputed<List>(() {
      if (searchKeyword.value.isEmpty) return others.value;
      return others.filter((v) =>
          v['dname']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()) ||
          v['desc']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()));
    });
    final filteredPackages = useComputed<List>(() {
      if (searchKeyword.value.isEmpty) return packages.value;
      return packages.filter((v) =>
          v['dname']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()) ||
          v['desc']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()));
    });
    final filteredBetas = useComputed<List>(() {
      if (searchKeyword.value.isEmpty) return betas.value;
      return betas.filter((v) =>
          v['dname']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()) ||
          v['desc']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()));
    });
    final filteredinstalledPackages = useComputed<List>(() {
      if (searchKeyword.value.isEmpty) return installedPackages.value;
      return installedPackages.filter((v) =>
          v['dname']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()) ||
          v['desc']
              .toString()
              .toLowerCase()
              .contains(searchKeyword.value.toLowerCase()));
    });

    void parseVersion() {
      String ver = version;
      int end = ver.indexOf("-");
      final dsmVersion = ver.substring(4, end);
      List v = dsmVersion.split(".");
      if (v[0] == "6" && v[1] == "1") {
        installedVersion.value = 1;
        packagesVersion.value = 1;
      } else if (v[0] == "5") {
        packagesVersion.value = 1;
        installedVersion.value = 1;
      } else if (v[0] == "6" && v[1] == "2" && v.length == 2) {
        installedVersion.value = 1;
        packagesVersion.value = 2;
      } else {
        packagesVersion.value = 2;
        installedVersion.value = 2;
      }
    }

    void fixPackage(ListSignal target) {
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
                installedPackages.indexWhere((t) => t['id'] == package['id']);
            if (idx != -1) {
              installedPackages.replaceRange(idx, idx + 1, package);
            } else {
              installedPackages.add(package);
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

    void fixAll() {
      fixPackage(packages);
      fixPackage(others);
      fixPackage(betas);
    }

    fetchVolumes() async {
      try {
        final res = await dsmCoreStorageVolumeList();
        volumes.value = res['volumes'] ?? [];
      } on Exception catch (e) {
        Log.error(e);
      }
    }

    fetchThird() async {
      try {
        final res = await dsmCorePackageServerList(
            blloadothers: true, version: packagesVersion.value);
        if (res['packages'] != null) {
          others.value = res['packages'] ?? [];
        } else {
          // fixme: res['data']
          others.value = [];
        }
      } on Exception catch (e) {
        Log.error(e);
        fixAll();
      }
      loadingOthers.value = false;
    }

    fetchLaunchedPackages() async {
      launchedPackages.clear();
      try {
        final res = await dsmCorePollingData();
        Map packageMap = res['packages'] ?? {};
        packageMap.forEach((key, value) {
          launchedPackages.add(key);
        });
        fixAll();
      } on Exception catch (e) {
        Log.error(e);
      }
    }

    fetchInstalledPackages() async {
      installedPackages.clear();
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
      if (installedVersion.value == 2) {
        additional.add("updated_at");
      }
      try {
        final res = await dsmCorePackageList(
            additional: jsonEncode(additional),
            pollingInterval: 15,
            version: installedVersion.value);
        installedPackagesInfo.value = res['packages'];
        loadingInstalled.value = false;
        fixAll();
      } on Exception catch (e) {
        Log.error(e);
      }
    }

    fetchData() async {
      try {
        loadingAll.value = true;
        final res =
            await dsmCorePackageServerList(version: packagesVersion.value);
        if (res['packages'] != null) {
          packages.value = res['packages'];
        } else {
          // fixme: res['data']
          packages.value = [];
        }
        if (res['beta_packages'] != null) {
          betas.value = res['beta_packages'];
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
      fetchThird();
      fetchLaunchedPackages();
      fetchInstalledPackages();
      fetchVolumes();
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
    Future<void> handleUpdatePackage(Map package, {bool beta = false}) async {
      Navigator.of(context)
          .push(CupertinoPageRoute(
              builder: (context) {
                return PackageDetail(package, beta: beta, method: "update");
              },
              settings: const RouteSettings(name: "package_detail")))
          .then((_) async {
        // await getLaunchedPackages();
        await fetchInstalledPackages();
        loading.value = false;
      });
    }

    // 处理安装套件
    Future<void> handleInstallPackage(Map package, {bool beta = false}) async {
      Navigator.of(context)
          .push(CupertinoPageRoute(
              builder: (context) {
                return PackageDetail(package, beta: beta, method: "install");
              },
              settings: const RouteSettings(name: "package_detail")))
          .then((_) async {
        // await getLaunchedPackages();
        await fetchInstalledPackages();
        loading.value = false;
      });
    }

    // 处理启动套件
    Future<void> handleStartPackage(Map package) async {
      loading.value = true;
      try {
        await dsmCorePackageControlStart(
            package['id'], jsonEncode(package['dsm_apps']));
        UiUtil.toast("已启动");
        await fetchInstalledPackages();
        loading.value = false;
      } on Exception catch (e) {
        Log.error(e);
      }
    }

    // 处理停止套件
    Future<void> handleStopPackage(Map package) async {
      loading.value = true;
      try {
        await dsmCorePackageControlStop(package['id']);
        UiUtil.toast("已停用");
        // await getLaunchedPackages();
        await fetchInstalledPackages();
        loading.value = false;
      } on Exception catch (e) {
        Log.error(e);
      }
    }

    Widget buildUpdateItem(update) {
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
            await fetchInstalledPackages();
            loading.value = false;
          });
        },
        onUpdate: () => handleUpdatePackage(update),
        onInstall: () => handleInstallPackage(update),
        onStart: () => handleStartPackage(update),
        onStop: () => handleStopPackage(update),
      );
    }

    Widget buildPackageItem(package, bool installed,
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
            await fetchInstalledPackages();
            loading.value = false;
          });
        },
        onUpdate: () => handleUpdatePackage(package, beta: isBeta),
        onInstall: () => handleInstallPackage(package, beta: isBeta),
        onStart: () => handleStartPackage(package),
        onStop: () => handleStopPackage(package),
      );
    }

    useEffect(() {
      void listener() {
        searchKeyword.value = searchController.text;
      }

      searchController.addListener(listener);
      parseVersion();
      fetchData();
      return () {
        searchController.removeListener(listener);
      };
    }, const []);

    // The tab count changes (3 -> 4) once the beta packages arrive, which
    // rebuilds the controller; the previous instance must be disposed.
    useEffect(() {
      return () {
        tabController.dispose();
      };
    }, [tabController]);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "套件中心",
        ),
        actions: [
          Builder(builder: (context) {
            if (showSearchBar.value) {
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
                icon: useGridLayout.value
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
                  controller: tabController,
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
                  controller: tabController,
                  children: [
                    Builder(builder: (context) {
                      if (loadingInstalled.value) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        );
                      } else {
                        if (useGridLayout.value) {
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
                                    return buildUpdateItem(
                                        canUpdatePackages[i]);
                                  },
                                  itemCount: canUpdatePackages.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                ),
                              ...filteredinstalledPackages.value.map((package) {
                                return buildPackageItem(package, true);
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
                                  return buildUpdateItem(canUpdatePackages[i]);
                                },
                                itemCount: canUpdatePackages.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                              ),
                            Wrap(
                              runSpacing: 20,
                              spacing: 20,
                              children:
                                  filteredinstalledPackages.value.map((package) {
                                return buildPackageItem(package, true,
                                    horizontal: true);
                              }).toList(),
                            ),
                          ],
                        );
                      }
                    }),
                    Builder(builder: (context) {
                      if (loadingAll.value) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        );
                      } else {
                        if (useGridLayout.value) {
                          return GridView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3),
                            children: filteredPackages.value.map((package) {
                              return buildPackageItem(package, false);
                            }).toList(),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          children: filteredPackages.value.map((package) {
                            return buildPackageItem(package, false,
                                horizontal: true);
                          }).toList(),
                        );
                      }
                    }),
                    Builder(builder: (context) {
                      if (loadingOthers.value) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        );
                      } else {
                        if (useGridLayout.value) {
                          return GridView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3),
                            children: filteredOthers.value.map((package) {
                              return buildPackageItem(package, false);
                            }).toList(),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          children: filteredOthers.value.map((package) {
                            return buildPackageItem(package, false,
                                horizontal: true);
                          }).toList(),
                        );
                      }
                    }),
                    if (filteredBetas.value.isNotEmpty)
                      ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        children: [
                          Wrap(
                            runSpacing: 20,
                            spacing: 20,
                            children: filteredBetas.value.map((package) {
                              return buildPackageItem(package, false,
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
          if (loading.value)
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

class _PackageTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
