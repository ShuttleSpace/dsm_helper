import 'dart:async';
import 'package:garden/extensions/context.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:garden/pages/packages/uninstall.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';


class PackageDetail extends HookWidget {
  final Map package;
  final bool beta;
  final String? method;
  const PackageDetail(this.package,
      {super.key, this.beta = false, this.method});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = useSignal("");
    final installVolume = useSignal("");
    final installPath = useSignal("");
    final volumes = useSignal<List>([]);
    final installProgress = useSignal(0.0);
    final installing = useSignal(false);
    final timer = useRef<Timer?>(null);
    final installButtonText = useSignal("安装");

    getLaunchedPackages() async {
      package['launched'] = true;
      package['can_update'] = false;
    }

    install(path) async {
      late Map<String, dynamic> data;
      try {
        data = await dsmCorePackageInstallTaskForPage(package['id'], path);
      } on DSMException catch (e) {
        if (e.code == 4501) {
          UiUtil.toast("此套件需配置信息，当前暂不支持，请在WEB端安装");
        } else {
          UiUtil.toast("安装套件失败，代码${e.code}");
        }
        return;
      } catch (e) {
        UiUtil.toast("安装套件失败，代码-1");
        return;
      }
      Log.info(data);
      UiUtil.toast("已开始安装");
      installing.value = true;
      installButtonText.value = "准备安装…";
      installProgress.value = double.parse(data['progress'].toString());
      timer.value = Timer.periodic(const Duration(seconds: 5), (unusedTimer) async {
        try {
          final value = await dsmCorePackageInstallStatusForPage(data['taskid']);
          Log.info(value);
          installing.value = value['finished'] != true;
          if (value['finished'] == true) {
            package['installed'] = true;
            getLaunchedPackages();
            timer.value?.cancel();
          } else if (value['progress'] != null) {
            installProgress.value = (value['progress'] is double)
                ? value['progress']
                : double.parse(value['progress'].toString());
            installButtonText.value = "下载中:${installProgress.value.toStringAsFixed(2)}%";
          } else if (value['status'] == "installing") {
            installButtonText.value = "安装中…";
          } else if (value['status'] == 'upgrading') {
            installButtonText.value = "更新中…";
          }
        } catch (e) {
          Log.warn('install status: $e');
        }
      });
    }
    selectVolume() {
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return SizedBox(
            width: double.infinity,
            child: Material(
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
                        "选择套件安装位置",
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ...volumes.map((volume) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: OutlinedButton(
                            onPressed: () async {
                              install(volume['volume_path']);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.only(left: 20),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${volume['display_name']}(可用容量：${int.parse(volume['size_free_byte']).formatSize()}) - ${volume['fs_type']}"),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    "${volume['description']}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "取消",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          );
        },
      );
    }

    update() async {
    
      installButtonText.value = "请稍后";
  
      late Map<String, dynamic> data;
      try {
        data = await dsmCorePackageInstallQueueForPage(
            package['id'], package['version'],
            beta: beta);
      } catch (e) {
        installButtonText.value = "更新";
        return;
      }
      {
        if ((data['paused_pkgs'] as List?)?.isNotEmpty == true && context.mounted) {
          showCupertinoModalPopup(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) {
              return SizedBox(
                width: double.infinity,
                child: Material(
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
                            "确认更新",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            '更新${data['cause_pausing_pkgs'].join(",")}时，${data['paused_pkgs'].join("，")}将被停用。',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 22,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    install(installPath.value);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    "继续更新",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.redAccent),
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
              ),
              );
            },
          ).then((value) {
          
            installButtonText.value = "更新";
        
          });
        } else {
          install(installPath.value);
        }
      }
    }

    uninstallPackage() async {
      try {
        await dsmCorePackageUninstallTaskForPage(package['id']);
        UiUtil.toast("卸载成功");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      } catch (e) {
        final code = e is DSMException ? e.code : -1;
        UiUtil.toast("套件卸载失败，错误代码：$code");
      }
    }
    getVolumes() async {
      try {
        final data = await dsmCoreStorageVolumeListForPage();
        volumes.value = data['volumes'] ?? [];
    
        if (method == "install") {
          selectVolume();
        } else if (method == "update") {
          update();
        }
      } catch (e) {
        Log.warn('volumes: $e');
      }
    }

    Widget buildSwiperItem(String url) {
      if (!url.startsWith("http")) {
        url = connectionStore.baseUri + url;
      }
      return CupertinoExtendedImage(
        url,
        height: 210,
        fit: BoxFit.contain,
      );
    }

    useEffect(() {
      if (package['installed'] && package['additional'] != null) {
        installPath.value = package['additional']['installed_info']['path']
            .split("/@appstore")[0];
        if (package['additional']['installed_info']['path']
            .contains("volume")) {
          List paths =
              package['additional']['installed_info']['path'].split("/");
          installVolume.value = paths[1];
        } else {
          installVolume.value = "系统分区";
        }
      }
      if (package['can_update']) {
        installButtonText.value = "更新";
      }
      thumbnailUrl.value = package['thumbnail'].last;
      if (!thumbnailUrl.value.startsWith("http")) {
        thumbnailUrl.value =
            connectionStore.baseUri.value + thumbnailUrl.value;
      }
      getVolumes();
      return () {
        timer.value?.cancel();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "${package['dname']}",
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CupertinoExtendedImage(
                          thumbnailUrl.value,
                          width: 60,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${package['dname']}"),
                              if (package['installed'])
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: package['launched']
                                      ? const Label("已启动", Colors.green)
                                      : const Label("已停用", Colors.red),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                if (package['snapshot'] != null &&
                    package['snapshot'].length > 0)
                  Card(
                    shape: context.roundRectShapeBorder,
                    margin: const EdgeInsets.only(top: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 210,
                            child: Swiper(
                              autoplay: true,
                              autoplayDelay: 5000,
                              pagination: const SwiperPagination(
                                  alignment: Alignment.bottomCenter,
                                  builder: DotSwiperPaginationBuilder(
                                      activeColor: Colors.lightBlueAccent,
                                      size: 7,
                                      activeSize: 7)),
                              itemCount: package['snapshot'].length,
                              itemBuilder: (context, i) {
                                return buildSwiperItem(
                                    package['snapshot'][i]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.only(top: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "描述",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text("${package['desc']}"),
                      ],
                    ),
                  ),
                ),
                if (package['changelog'] != "")
                  Card(
                    shape: context.roundRectShapeBorder,
                    margin: const EdgeInsets.only(top: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${package['version']}新增功能",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          // SizedBox(
                          //   height: 20,
                          // ),
                          Html(
                            data: package['changelog'],
                            onLinkTap: (link, _, __) {
                              AndroidIntent intent = AndroidIntent(
                                action: 'action_view',
                                data: link,
                                arguments: {},
                              );
                              intent.launch();
                            },
                            style: {
                              "ol": Style(
                                padding: HtmlPaddings.all(0),
                                margin: Margins.zero,
                              ),
                              "li": Style(),
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.only(top: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "其他信息",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("开发者"),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    if (package['maintainer_url'] !=
                                            null &&
                                        package['maintainer_url'] != "")
                                      GestureDetector(
                                        child: Text(
                                          "${package['maintainer']}",
                                          style: const TextStyle(
                                              color: Colors.blue),
                                        ),
                                        onTap: () {
                                          AndroidIntent intent = AndroidIntent(
                                            action: 'action_view',
                                            data: package['maintainer_url'],
                                            arguments: {},
                                          );
                                          intent.launch();
                                        },
                                      )
                                    else
                                      Text(
                                        "${package['maintainer']}",
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (package['distributor'] != null &&
                                package['distributor'] != "")
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("发布人员"),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      if (package['distributor_url'] !=
                                              null &&
                                          package['distributor_url'] !=
                                              "")
                                        GestureDetector(
                                          child: Text(
                                            "${package['distributor']}",
                                            style: const TextStyle(
                                                color: Colors.blue),
                                          ),
                                          onTap: () {
                                            AndroidIntent intent =
                                                AndroidIntent(
                                              action: 'action_view',
                                              data: package['distributor_url'],
                                              arguments: {},
                                            );
                                            intent.launch();
                                          },
                                        )
                                      else
                                        Text(
                                          "${package['distributor']}",
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("下载次数"),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text("${package['download_count']}"),
                                  ],
                                ),
                              ),
                            ),
                            if (package['installed'])
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("已安装版本"),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                          "${package['installed_version']}"),
                                    ],
                                  ),
                                ),
                              ),
                            if (package['installed'])
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("安装位置"),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(installVolume.value.replaceAll(
                                          "volume", "存储空间 ")),
                                    ],
                                  ),
                                ),
                              ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("最新版本"),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text("${package['version']}"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              children: [
                if (package['installed']) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: OutlinedButton(
                        onPressed: () async {
                          if (package['additional']
                              ['is_uninstall_pages']) {
                            Navigator.of(context).push(CupertinoPageRoute(
                                builder: (context) {
                                  return UninstallPackage(package);
                                },
                                settings: const RouteSettings(
                                    name: "uninstall_package")));
                          } else {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: Material(
                                  color: Colors.transparent,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: SafeArea(
                                      top: false,
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingSmall),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Text(
                                              "卸载套件",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            const Text(
                                              "确认要卸载此套件？",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            const SizedBox(
                                              height: 22,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () async {
                                                      Navigator.of(context)
                                                          .pop();
                                                      uninstallPackage();
                                                    },
                                                    child: const Text(
                                                      "卸载",
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          color:
                                                              Colors.redAccent),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 20,
                                                ),
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () async {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text(
                                                      "取消",
                                                      style: TextStyle(
                                                          fontSize: 18),
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
                                ),
                                );
                              },
                            );
                          }
                        },
                        child: const Text(
                          "卸载",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  if (package['launched'] &&
                      package['additional'] != null &&
                      package['additional']['startable'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: package['launched']
                            ? OutlinedButton(
                                onPressed: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (context) {
                                      return SizedBox(
                                        width: double.infinity,
                                        child: Material(
                                        color: Colors.transparent,
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                              side: const BorderSide(),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: SafeArea(
                                            top: false,
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                  AppConstants.paddingSmall),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  const Text(
                                                    "停用套件",
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                  const Text(
                                                    "确认要停用此套件？",
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  const SizedBox(
                                                    height: 22,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            try {
                                                              await dsmCorePackageControlForPage(
                                                                  package['id'],
                                                                  package['dsm_apps'],
                                                                  "stop");
                                                              UiUtil.toast("已停用");
                                                              package['launched'] =
                                                                  false;
                                                              getLaunchedPackages();
                                                            } catch (e) {
                                                              Log.warn('stop package: $e');
                                                            }
                                                          },
                                                          child: const Text(
                                                            "停用",
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: Colors
                                                                    .redAccent),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 20,
                                                      ),
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                            "取消",
                                                            style: TextStyle(
                                                                fontSize: 18),
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
                                      ),
                                      );
                                    },
                                  );
                                },
                                child: const Text("停用"),
                              )
                            : OutlinedButton(
                                onPressed: () async {
                                  try {
                                    await dsmCorePackageControlForPage(
                                        package['id'],
                                        package['dsm_apps'],
                                        "start");
                                    UiUtil.toast("已启动");
                                    package['launched'] = true;
                                  } catch (e) {
                                    Log.warn('start package: $e');
                                  }
                                },
                                child: const Text("启动"),
                              ),
                      ),
                    ),
                ] else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: OutlinedButton(
                        onPressed: () {
                          selectVolume();
                        },
                        child: Text(installButtonText.value),
                      ),
                    ),
                  ),
                if (package['can_update'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: OutlinedButton(
                        onPressed: () async {
                          update();
                          // install(volume['volume_path']);
                        },
                        child: Text(installButtonText.value),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
