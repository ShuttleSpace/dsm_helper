import 'dart:async';
import 'dart:math';

import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class MediaConverter extends HookWidget {
  final Map converter;
  const MediaConverter(this.converter, {super.key});

  @override
  Widget build(BuildContext context) {
    final converterValue = useSignal<Map>(converter);

    getMediaConverter() async {
      var res = await DsmApi.mediaConverter("status");
      if (res['success'] && context.mounted) {
        converterValue.value = res['data'];
        Log.info("get media converter status $res}");
      }
    }

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        getMediaConverter();
      });
      getMediaConverter();
      return () {
        timer.cancel();
        Log.info("取消计时器");
      };
    }, const []);

    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "转换进程",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 12,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                  text: "图像：",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 18)),
                              TextSpan(
                                  text: "共 ${converterValue.value['photo_total']} 个图像")
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FAProgressBar(
                          backgroundColor: Colors.transparent,
                          progressColor: Colors.blue,
                          currentValue: max(
                              converterValue.value['photo_remain'] > 0
                                  ? ((converterValue.value['photo_total'] -
                                              converterValue.value['photo_remain']) *
                                          100 /
                                          converterValue.value['photo_total'])
                                      .ceil()
                                  : 0,
                              converterValue.value['thumb_remain'] > 0
                                  ? ((converterValue.value['thumb_total'] -
                                              converterValue.value['thumb_remain']) *
                                          100 /
                                          converterValue.value['thumb_total'])
                                      .ceil()
                                  : 0),
                          displayText: '%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                  text: "视频：",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 18)),
                              TextSpan(text: "共 ${converterValue.value['video_total']}个视频")
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FAProgressBar(
                          backgroundColor: Colors.transparent,
                          progressColor: Colors.blue,
                          currentValue: converterValue.value['video_total'] > 0
                              ? (converterValue.value['video_remain'] *
                                      100 /
                                      converterValue.value['video_total'])
                                  .ceil()
                              : 0,
                          displayText: '%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                    text: "状态：",
                                    style: TextStyle(
                                        color: Colors.blue, fontSize: 18)),
                                TextSpan(
                                  text:
                                      "${converterValue.value['status'] == "converting" ? "转换中" : converterValue.value['status'] == "paused" ? "已暂停" : converterValue.value['status']}",
                                ),
                                if (converterValue.value['resume_time'] > 0)
                                  TextSpan(
                                      text:
                                          " (${DateTime.fromMillisecondsSinceEpoch(converterValue.value['resume_time'] * 1000).format("H:i")}恢复)",
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                if (converterValue.value['resume_time'] < 0)
                                  const TextSpan(
                                      text: " (无限期延迟)",
                                      style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (converterValue.value['status'] == "paused") {
                              var res = await DsmApi.mediaConverter("resume");
                              if (res['success']) {
                                getMediaConverter();
                              }
                            } else {
                              showCupertinoModalPopup(
                                  context: context,
                                  builder: (context) {
                                    return Material(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingLarge),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              "延迟转换",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pop(1);
                                              },
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                    side: const BorderSide(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                margin: const EdgeInsets.only(
                                                    bottom: 20),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    "延迟1小时",
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pop(3);
                                              },
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                    side: const BorderSide(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                margin: const EdgeInsets.only(
                                                    bottom: 20),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    "延迟3小时",
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pop(6);
                                              },
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                    side: const BorderSide(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                margin: const EdgeInsets.only(
                                                    bottom: 20),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    "延迟6小时",
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pop(-1);
                                              },
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                    side: const BorderSide(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                margin: const EdgeInsets.only(
                                                    bottom: 20),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    "无限期延迟",
                                                  ),
                                                ),
                                              ),
                                            ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                "取消",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).then((value) async {
                                if (value != null) {
                                  var res = await DsmApi.mediaConverter("pause",
                                      hours: value);
                                  if (res['success']) {
                                    getMediaConverter();
                                  }
                                }
                              });
                            }
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Icon(
                              converterValue.value['status'] == "paused"
                                  ? CupertinoIcons.play_arrow_solid
                                  : CupertinoIcons.pause_fill,
                              color: AppColors.primaryAction,
                              size: 16,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "确定",
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
  }
}
