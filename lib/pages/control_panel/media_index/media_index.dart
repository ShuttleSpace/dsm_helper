import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class MediaIndex extends HookWidget {
  const MediaIndex({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaIndexing = useSignal(false);
    final thumbnailQuality = useSignal("");
    final mobileEnabled = useSignal(false);
    final packages = useSignal<List>([]);

    Future<void> getData() async {
      try {
        final apis = <Map<String, dynamic>>[
          {
            "api": "SYNO.Core.MediaIndexing.ThumbnailQuality",
            "method": "get",
            "version": 1
          },
          {"api": "SYNO.Core.MediaIndexing", "method": "status", "version": 1}
        ];
        if (connectionStore.dsmVersion.value == 6) {
          apis.add({
            "api": "SYNO.Core.MediaIndexing.MobileEnabled",
            "method": "get",
            "version": 1
          });
        }
        final data = await dsmControlPanelPost({
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
            case "SYNO.Core.MediaIndexing":
              mediaIndexing.value = itemData['reindexing'] ?? false;
              break;
            case "SYNO.Core.MediaIndexing.ThumbnailQuality":
              thumbnailQuality.value = itemData['thumbnail_quality'] ?? '';
              packages.value = itemData['packages'] ?? [];
              break;
            case "SYNO.Core.MediaIndexing.MobileEnabled":
              mobileEnabled.value = itemData['mobile_profile_enabled'] ?? false;
              break;
          }
        }
      } catch (e) {
        // 旧层失败时保持原状态。
      }
    }

    Future<void> saveMediaIndex() async {
      final apis = <Map<String, dynamic>>[
        {
          "api": "SYNO.Core.MediaIndexing.ThumbnailQuality",
          "method": "set",
          "version": "1",
          "thumbnail_quality": thumbnailQuality.value,
        }
      ];
      if (connectionStore.dsmVersion.value == 6) {
        apis.add({
          "api": "SYNO.Core.MediaIndexing.MobileEnabled",
          "method": "set",
          "version": "1",
          "mobile_profile_enabled": mobileEnabled.value,
        });
      }
      try {
        await dsmControlPanelPost({
          "api": 'SYNO.Entry.Request',
          "method": 'request',
          "mode": '"sequential"',
          "compound": jsonEncode(apis),
          "version": 1,
        });
      } catch (e) {
        // 旧层忽略设置失败。
      }
    }

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        getData();
      });
      getData();
      return () {
        timer.cancel();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("索引服务"),
      ),
      body: ListView(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "媒体索引",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        mediaIndexing.value ? "索引中" : "已完成",
                        style: TextStyle(
                            color: mediaIndexing.value
                                ? Colors.blue
                                : Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          "媒体索引功能会自动扫描存储在 DiskStation 中的多媒体文件如照片、音乐和视频，并为这些文件创建索引以供多媒体应用程序使用。"),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                          "请注意，只有“/photo”共享文件夹内的图像文件才会在创建索引后添加到 Photo Station。"),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Text(
                              "应用程序：${packages.value.map((e) => e['name']).join("，")}"),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          if (mediaIndexing.value) {
                            return;
                          }
                          try {
                            await dsmControlPanelPost({
                              "api": "SYNO.Core.MediaIndexing",
                              "method": "reindex",
                              "version": 1,
                            });
                            await getData();
                          } catch (e) {
                            // 旧层失败时静默。
                          }
                        },
                        child: Text(
                          "重建索引",
                          style: TextStyle(
                              color: mediaIndexing.value == true
                                  ? Colors.grey
                                  : null),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "缩图设置",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          "当您上传照片或视频供媒体服务器和 Photo Station 使用时，系统会创建缩略图来提供更好的浏览体验。您可以在此设置缩略图品质并查看创建进程。"),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text("注意: 创建高品质缩略图将耗用较多的时间。"),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Text("缩图品质："),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                thumbnailQuality.value = "normal";
                                await saveMediaIndex();
                                await getData();
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: Row(
                                    children: [
                                      const Text("一般品质"),
                                      const Spacer(),
                                      if (thumbnailQuality.value == "normal")
                                        const Icon(
                                          CupertinoIcons.checkmark_alt,
                                          color: AppColors.primaryAction,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                thumbnailQuality.value = "high";
                                await saveMediaIndex();
                                await getData();
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: Row(
                                    children: [
                                      const Text("高品质"),
                                      const Spacer(),
                                      if (thumbnailQuality.value == "high")
                                        const Icon(
                                          CupertinoIcons.checkmark_alt,
                                          color: AppColors.primaryAction,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "视频设置",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          "若要在移动设备上查看 Photo Station 中“photo”共享文件夹内的视频，您可以为移动设备启用视频格式转换的功能。"),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text("注意: 启用此选项将耗用较多的时间和 CPU 资源。"),
                      const SizedBox(
                        height: 10,
                      ),
                      GestureDetector(
                        onTap: () async {
                          mobileEnabled.value = !mobileEnabled.value;
                          await saveMediaIndex();
                          await getData();
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(),
                              borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppConstants.paddingSmall),
                            child: Row(
                              children: [
                                const Text("启用移动设备视频转换"),
                                const Spacer(),
                                if (mobileEnabled.value)
                                  const Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color: AppColors.primaryAction,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}
