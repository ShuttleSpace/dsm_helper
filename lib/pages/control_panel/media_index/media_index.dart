import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'dart:async';

class MediaIndex extends StatefulWidget {
  const MediaIndex({super.key});

  @override
  MediaIndexState createState() => MediaIndexState();
}

class MediaIndexState extends State<MediaIndex> {
  bool mediaIndexing = false;
  String thumbnailQuality = "";
  bool mobileEnabled = false;
  List packages = [];
  late Timer timer;
  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      getData();
    });
    getData();
    super.initState();
  }

  getData() async {
    Api.mediaIndexStatus().then((res) {
      if (res['success']) {
        List result = res['data']['result'];
        for (var item in result) {
          if (item['success'] == true) {
            switch (item['api']) {
              case "SYNO.Core.MediaIndexing":
                setState(() {
                  mediaIndexing = item['data']['reindexing'];
                });
                break;
              case "SYNO.Core.MediaIndexing.ThumbnailQuality":
                setState(() {
                  thumbnailQuality = item['data']['thumbnail_quality'];
                  packages = item['data']['packages'];
                });
                break;
              case "SYNO.Core.MediaIndexing.MobileEnabled":
                setState(() {
                  mobileEnabled = item['data']['mobile_profile_enabled'];
                });
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        mediaIndexing ? "索引中" : "已完成",
                        style: TextStyle(
                            color: mediaIndexing ? Colors.blue : Colors.green),
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
                              "应用程序：${packages.map((e) => e['name']).join("，")}"),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          if (mediaIndexing) {
                            return;
                          }
                          var res = await Api.mediaReindex();
                          if (res['success']) {
                            getData();
                          }
                        },
                        child: Text(
                          "重建索引",
                          style: TextStyle(
                              color:
                                  mediaIndexing == true ? Colors.grey : null),
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
                                setState(() {
                                  thumbnailQuality = "normal";
                                });
                                await Api.mediaIndexSet(
                                    thumbnailQuality, mobileEnabled);
                                getData();
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
                                      if (thumbnailQuality == "normal")
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
                                setState(() {
                                  thumbnailQuality = "high";
                                });
                                await Api.mediaIndexSet(
                                    thumbnailQuality, mobileEnabled);
                                getData();
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
                                      if (thumbnailQuality == "high")
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
                          setState(() {
                            mobileEnabled = !mobileEnabled;
                          });
                          await Api.mediaIndexSet(
                              thumbnailQuality, mobileEnabled);
                          getData();
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
                                if (mobileEnabled)
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
