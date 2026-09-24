import 'dart:async';
import 'package:garden/extensions/context.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:garden/pages/packages/uninstall.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:signals/signals_flutter.dart';

class PackageDetail extends StatefulWidget {
  final Map package;
  final bool beta;
  final String? method;
  const PackageDetail(this.package,
      {super.key, this.beta = false, this.method});
  @override
  PackageDetailState createState() => PackageDetailState();
}

class PackageDetailState extends State<PackageDetail> {
  String thumbnailUrl = "";
  String installVolume = "";
  String installPath = "";
  List volumes = [];
  double installProgress = 0;
  bool installing = false;
  Timer? timer;
  String taskId = "";
  String installButtonText = "安装";
  @override
  void initState() {
    if (widget.package['installed'] && widget.package['additional'] != null) {
      setState(() {
        installPath = widget.package['additional']['installed_info']['path']
            .split("/@appstore")[0];
        if (widget.package['additional']['installed_info']['path']
            .contains("volume")) {
          List paths =
              widget.package['additional']['installed_info']['path'].split("/");
          installVolume = paths[1];
        } else {
          installVolume = "系统分区";
        }
      });
    }
    if (widget.package['can_update']) {
      setState(() {
        installButtonText = "更新";
      });
    }
    thumbnailUrl = widget.package['thumbnail'].last;
    if (!thumbnailUrl.startsWith("http")) {
      thumbnailUrl = connectionStore.baseUri.watch(context) + thumbnailUrl;
    }
    getVolumes();
    super.initState();
  }

  getVolumes() async {
    var res = await DsmApi.volumes();
    if (res['success']) {
      setState(() {
        volumes = res['data']['volumes'];
      });
      if (widget.method == "install") {
        selectVolume();
      } else if (widget.method == "update") {
        update();
      }
    }
  }

  Widget _buildSwiperItem(String url) {
    if (!url.startsWith("http")) {
      url = connectionStore.baseUri + url;
    }
    return CupertinoExtendedImage(
      url,
      height: 210,
      fit: BoxFit.contain,
    );
  }

  selectVolume() {
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
        );
      },
    );
  }

  getLaunchedPackages() async {
    widget.package['launched'] = true;
    widget.package['can_update'] = false;
  }

  update() async {
    setState(() {
      installButtonText = "请稍后";
    });
    var res = await DsmApi.installPackageQueue(
        widget.package['id'], widget.package['version'],
        beta: widget.beta);
    if (res['success']) {
      if (res['data']['paused_pkgs'].length > 0 && context.mounted) {
        showCupertinoModalPopup(
          // ignore: use_build_context_synchronously
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
                          "确认更新",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          '更新${res['data']['cause_pausing_pkgs'].join(",")}时，${res['data']['paused_pkgs'].join("，")}将被停用。',
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
                                  install(installPath);
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
            );
          },
        ).then((value) {
          setState(() {
            installButtonText = "更新";
          });
        });
      } else {
        install(installPath);
      }
    }
  }

  uninstallPackage() async {
    var res = await DsmApi.uninstallPackageTask(widget.package['id']);
    if (res['success']) {
      UiUtil.toast("卸载成功");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    } else {
      UiUtil.toast("套件卸载失败，错误代码：${res['error']['code']}");
    }
  }

  install(path) async {
    var res = await DsmApi.installPackageTask(widget.package['id'], path);
    Log.info(res);
    if (res['success']) {
      UiUtil.toast("已开始安装");
      setState(() {
        installing = true;
        installButtonText = "准备安装…";
        installProgress = double.parse(res['data']['progress']);
      });
      //进度
      timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        DsmApi.installPackageStatus(res['data']['taskid']).then((value) {
          Log.info(value);
          setState(() {
            installing = !value['data']['finished'];
            if (value['data']['finished']) {
              widget.package['installed'] = true;
              getLaunchedPackages();
              timer.cancel();
            } else if (value['data']['progress'] != null) {
              if (value['data']['progress'] is double) {
                installProgress = value['data']['progress'];
              } else {
                installProgress = double.parse(value['data']['progress']);
              }
              installButtonText = "下载中:${installProgress.toStringAsFixed(2)}%";
            } else if (value['data']['status'] == "installing") {
              installButtonText = "安装中…";
            } else if (value['data']['status'] == 'upgrading') {
              installButtonText = "更新中…";
            }
          });
        });
      });
    } else if (res['error']['code'] == 4501) {
      UiUtil.toast("此套件需配置信息，当前暂不支持，请在WEB端安装");
    } else {
      UiUtil.toast("安装套件失败，代码${res['error']['code']}");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "${widget.package['dname']}",
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
                          thumbnailUrl,
                          width: 60,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${widget.package['dname']}"),
                              if (widget.package['installed'])
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: widget.package['launched']
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
                if (widget.package['snapshot'] != null &&
                    widget.package['snapshot'].length > 0)
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
                              itemCount: widget.package['snapshot'].length,
                              itemBuilder: (context, i) {
                                return _buildSwiperItem(
                                    widget.package['snapshot'][i]);
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
                        Text("${widget.package['desc']}"),
                      ],
                    ),
                  ),
                ),
                if (widget.package['changelog'] != "")
                  Card(
                    shape: context.roundRectShapeBorder,
                    margin: const EdgeInsets.only(top: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.package['version']}新增功能",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          // SizedBox(
                          //   height: 20,
                          // ),
                          Html(
                            data: widget.package['changelog'],
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
                                    if (widget.package['maintainer_url'] !=
                                            null &&
                                        widget.package['maintainer_url'] != "")
                                      GestureDetector(
                                        child: Text(
                                          "${widget.package['maintainer']}",
                                          style: const TextStyle(
                                              color: Colors.blue),
                                        ),
                                        onTap: () {
                                          AndroidIntent intent = AndroidIntent(
                                            action: 'action_view',
                                            data: widget
                                                .package['maintainer_url'],
                                            arguments: {},
                                          );
                                          intent.launch();
                                        },
                                      )
                                    else
                                      Text(
                                        "${widget.package['maintainer']}",
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.package['distributor'] != null &&
                                widget.package['distributor'] != "")
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
                                      if (widget.package['distributor_url'] !=
                                              null &&
                                          widget.package['distributor_url'] !=
                                              "")
                                        GestureDetector(
                                          child: Text(
                                            "${widget.package['distributor']}",
                                            style: const TextStyle(
                                                color: Colors.blue),
                                          ),
                                          onTap: () {
                                            AndroidIntent intent =
                                                AndroidIntent(
                                              action: 'action_view',
                                              data: widget
                                                  .package['distributor_url'],
                                              arguments: {},
                                            );
                                            intent.launch();
                                          },
                                        )
                                      else
                                        Text(
                                          "${widget.package['distributor']}",
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
                                    Text("${widget.package['download_count']}"),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.package['installed'])
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
                                          "${widget.package['installed_version']}"),
                                    ],
                                  ),
                                ),
                              ),
                            if (widget.package['installed'])
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
                                      Text(installVolume.replaceAll(
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
                                    Text("${widget.package['version']}"),
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
                if (widget.package['installed']) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: OutlinedButton(
                        onPressed: () async {
                          if (widget.package['additional']
                              ['is_uninstall_pages']) {
                            Navigator.of(context).push(CupertinoPageRoute(
                                builder: (context) {
                                  return UninstallPackage(widget.package);
                                },
                                settings: const RouteSettings(
                                    name: "uninstall_package")));
                          } else {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) {
                                return Material(
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
                  if (widget.package['launched'] &&
                      widget.package['additional'] != null &&
                      widget.package['additional']['startable'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: widget.package['launched']
                            ? OutlinedButton(
                                onPressed: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (context) {
                                      return Material(
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
                                                            var res = await DsmApi
                                                                .launchPackage(
                                                                    widget.package[
                                                                        'id'],
                                                                    widget.package[
                                                                        'dsm_apps'],
                                                                    "stop");
                                                            if (res[
                                                                'success']) {
                                                              UiUtil.toast(
                                                                  "已停用");
                                                              setState(() {
                                                                widget.package[
                                                                        'launched'] =
                                                                    false;
                                                              });
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
                                      );
                                    },
                                  );
                                },
                                child: const Text("停用"),
                              )
                            : OutlinedButton(
                                onPressed: () async {
                                  var res = await DsmApi.launchPackage(
                                      widget.package['id'],
                                      widget.package['dsm_apps'],
                                      "start");
                                  Log.info(res);
                                  if (res['success']) {
                                    UiUtil.toast("已启动");
                                    setState(() {
                                      widget.package['launched'] = true;
                                    });
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
                        child: Text(installButtonText),
                      ),
                    ),
                  ),
                if (widget.package['can_update'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: OutlinedButton(
                        onPressed: () async {
                          update();
                          // install(volume['volume_path']);
                        },
                        child: Text(installButtonText),
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
