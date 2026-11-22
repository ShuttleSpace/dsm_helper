import 'dart:async';

import 'package:garden/models/photos/photo_model.dart';
import 'package:garden/models/photos/timeline_model.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/list_cache.dart';
import 'package:garden/util/log.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Timeline extends HookWidget {
  const Timeline(this.isTeam,
      {super.key,
      this.type,
      this.geocodingId = 0,
      this.generalTagId = 0,
      this.recentlyAdd = false});
  final bool isTeam;
  final String? type;
  final int geocodingId;
  final int generalTagId;
  final bool recentlyAdd;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final loading = useSignal(true);
    final days = useSignal<List<Day>>([]);
    final double photoWidth = (MediaQuery.sizeOf(context).width - 6) / 4;

    String cacheKey({required bool isTeam}) =>
        'photos|timeline|$isTeam|$type|$geocodingId|$generalTagId|$recentlyAdd';

    List<Day> layout(List<TimelineModel> timelines) {
      final newDays = <Day>[];
      for (var timeline in timelines) {
        newDays.addAll(timeline.days as Iterable<Day>);
      }
      for (int i = 0; i < newDays.length; i++) {
        int rowCount = (newDays[i].itemCount ?? 0 / 4).ceil();
        double height = 40 + rowCount * photoWidth + (rowCount - 1) * 2;
        newDays[i].startPosition = i == 0 ? 0 : newDays[i - 1].endPosition;
        newDays[i].endPosition = newDays[i].startPosition ?? 0 + height;
      }
      return newDays;
    }

    Future getData({bool isTeam = false}) async {
      final key = cacheKey(isTeam: isTeam);
      // 先显示上次的列表快照，再后台刷新；没有快照才转圈等网络。
      final snapshot = await ListCache.read(key) as List?;
      if (snapshot != null && snapshot.isNotEmpty) {
        days.value =
            layout([for (final e in snapshot) TimelineModel.fromJson(e)]);
        loading.value = false;
      } else {
        loading.value = true;
      }
      try {
        final timelines = await TimelineModel.fetch(
          isTeam: isTeam,
          type: type,
          itemTypes: const <int>[],
          geocodingId: geocodingId,
          generalTagId: generalTagId,
          recentlyAdd: recentlyAdd,
        );
        unawaited(ListCache.write(key, [for (final t in timelines) t.toJson()]));
        days.value = layout(timelines);
      } catch (e) {
        // 刷新失败时保留快照，不要把已经显示的列表清掉。
        Log.error('timeline 刷新失败: $e');
      } finally {
        loading.value = false;
      }
    }

    Widget buildPhotoItem(PhotoModel photo, List<PhotoModel> photos) {
      return GestureDetector(
        onTap: () {
          if (photo.type == 'video') {
            Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
              return VideoPlayerPage(
                url: photo.videoUrl(isTeam: isTeam),
                cover: photo.thumbUrl(isTeam: isTeam),
              );
            }));
          } else {
            Navigator.of(context).push(TransparentPageRoute(
              pageBuilder: (context, _, __) {
                return ImagePreview(
                  photos
                      .map((photo) =>
                          photo.thumbUrl(size: 'xl', isTeam: isTeam))
                      .toList(),
                  photos.indexOf(photo),
                  tag: photo,
                );
              },
            ));
          }
        },
        child: SizedBox(
          width: photoWidth,
          height: photoWidth,
          child: Stack(
            children: [
              Hero(
                tag: photo,
                child: CupertinoExtendedImage(
                  photo.thumbUrl(isTeam: isTeam),
                  width: photoWidth,
                  height: photoWidth,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: photoWidth,
                    height: photoWidth,
                    color: AppColors.placeholderBackgroundLight,
                  ),
                ),
              ),
              if (photo.type == "video")
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${photo.additional?.videoMeta?.hours.toString().padLeft(2, "0")}:${photo.additional?.videoMeta?.minutes.toString().padLeft(2, "0")}:${photo.additional?.videoMeta?.seconds.toString().padLeft(2, "0")}",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      );
    }

    Widget buildTimelineItem(Day day) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            height: 40,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge),
            child: Row(
              children: [
                Text(
                  "${day.year}-${day.month.toString().padLeft(2, "0")}-${day.day.toString().padLeft(2, "0")}",
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: day.photos == null
                ? List.generate(day.itemCount?.toInt() ?? 0, (index) {
                    return Container(
                      // color: AppColors.placeholderBackgroundLight,
                      color: Colors.amber,
                      width: photoWidth,
                      height: photoWidth,
                    );
                  })
                : day.photos?.map((item) {
                      return buildPhotoItem(item, day.photos ?? []);
                    }).toList() ??
                    [
                      Container(
                        color: Colors.red,
                        width: 10,
                        height: 10,
                      )
                    ],
          ),
        ],
      );
    }

    useEffect(() {
      getData(isTeam: isTeam);
      return null;
    }, [isTeam]);

    return loading.value
        ? const Center(
            child: CupertinoActivityIndicator(
              radius: 14,
            ),
          )
        : days.value.isNotEmpty
            ? Scrollbar(
                controller: scrollController,
                child: ListView.builder(
                  controller: scrollController,
                  itemBuilder: (context, i) {
                    if (days.value[i].photos != null) {
                      return buildTimelineItem(days.value[i]);
                    }
                    return FutureBuilder(
                        future: days.value[i].fetchPhotos(
                          isTeam: isTeam,
                          type: type,
                          itemTypes: const <int>[],
                          geocodingId: geocodingId,
                          generalTagId: generalTagId,
                          recentlyAdd: recentlyAdd,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return buildTimelineItem(days.value[i]);
                          }
                        });
                  },
                  itemCount: days.value.length,
                ),
              )
            : const Center(
                child: Text("无项目"),
              );
  }
}
