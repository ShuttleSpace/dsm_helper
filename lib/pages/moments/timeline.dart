import 'package:garden/api/dsm_api.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Timeline extends HookWidget {
  final String? category;
  final String? type;
  final String title;
  const Timeline(this.title, {super.key, this.category, this.type});

  @override
  Widget build(BuildContext context) {
    final timeline = useSignal<List>([]);
    final loadingTimeline = useSignal(true);
    final scrollController = useScrollController();
    final dsmVersion = useSignalValue(connectionStore.dsmVersion);
    final sid = useSignalValue(connectionStore.sid);
    final baseUri = useSignalValue(connectionStore.baseUri);
    const double photoWidth = 0;

    getData() async {
      var res = await dsmFotoBrowseTimeline(category: category, type: type);
      if (context.mounted) {
        timeline.value = [];
        if (dsmVersion == 7) {
          for (var section in res['section']) {
            timeline.value = [...timeline.value, ...section['list']];
          }
        } else {
          timeline.value = res['list'];
        }
        for (int i = 0; i < timeline.value.length; i++) {
          int lines = (timeline.value[i]['item_count'] / 4).ceil();
          double height = 40 + lines * photoWidth + (lines - 1) * 2;
          timeline.value[i]['position'] = {};
          if (i == 0) {
            timeline.value[i]['position']['start'] = 0;
            timeline.value[i]['position']['end'] = height;
          } else {
            timeline.value[i]['position']['start'] =
                timeline.value[i - 1]['position']['end'];
            timeline.value[i]['position']['end'] =
                timeline.value[i]['position']['start'] + height;
          }
        }
        loadingTimeline.value = false;
      }
    }

    getLineInfo(line) async {
      if (line['items'] == null) {
        line['items'] = [];
        dsmFotoBrowsePhotoList(
                year: line['year'],
                month: line['month'],
                day: line['day'],
                type: type,
                category: category == "Timeline" ? "Item" : category)
            .then((res) {
          if (context.mounted) {
            line['items'] = res['list'];
            timeline.value = List.of(timeline.value);
          }
        });
      }
      if (line['location'] == null) {
        line['location'] = {};
        dsmFotoBrowseTimelineLocation(line['year'], line['month'], line['day'])
            .then((res) {
          if (context.mounted) {
            line['location'] = res;
            timeline.value = List.of(timeline.value);
          }
        });
      }
    }

    Widget buildPhotoItem(photo) {
      int duration = 0;
      Map timeLong = {};
      if (photo['type'] == "video") {
        if (photo['additional']['video_convert'].length > 0) {
          duration = photo['additional']['video_convert'][0]['metadata']
                  ['duration'] ~/
              1000;
          timeLong = duration.formatTime();
        } else {
          timeLong = {
            "hours": 0,
            "minutes": 0,
            "seconds": 0,
          };
        }
      }
      String thumbUrl =
          '$baseUri/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=$sid';
      String originalUrl =
          '$baseUri/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="xl"&api="SYNO.${dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=$sid';
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(TransparentPageRoute(
            pageBuilder: (context, _, __) {
              return ImagePreview(
                [originalUrl],
                0,
                tag:
                    "photo-timeline-${photo['additional']['thumbnail']['unit_id']}",
              );
            },
          ));
        },
        child: SizedBox(
          width: photoWidth,
          height: photoWidth,
          child: Stack(
            children: [
              Hero(
                tag:
                    "photo-timeline-${photo['additional']['thumbnail']['unit_id']}",
                child: CupertinoExtendedImage(
                  thumbUrl,
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
              if (photo['type'] == "video")
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
                        "${timeLong['hours'].toString().padLeft(2, "0")}:${timeLong['minutes'].toString().padLeft(2, "0")}:${timeLong['seconds'].toString().padLeft(2, "0")}",
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

    Widget buildTimelineItem(line) {
      getLineInfo(line);
      List items = line['items'];
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
                  "${line['year']}-${line['month'].toString().padLeft(2, "0")}-${line['day'].toString().padLeft(2, "0")}",
                ),
                if (line['location'] != null &&
                    ((line['location']['first_level'] != null &&
                        line['location']['first_level'] != "")))
                  Text("   ${line['location']['first_level']}"),
                if (line['location'] != null &&
                    ((line['location']['second_level'] != null &&
                        line['location']['second_level'].length > 0)))
                  Text("${line['location']['second_level'].join(",")}"),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            // crossAxisCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 2, crossAxisSpacing: 2),
            itemCount: line['item_count'],
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              if (items.isEmpty) {
                return Container(
                  color: Colors.grey,
                  width: photoWidth,
                  height: photoWidth,
                );
              } else {
                return buildPhotoItem(items[i]);
              }
            },
          ),
        ],
      );
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title),
      ),
      body: loadingTimeline.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : timeline.value.isNotEmpty
              ? DraggableScrollbar.semicircle(
                  labelTextBuilder: (position) {
                    var line = timeline.value
                        .where((element) =>
                            element['position']['start'] <= position &&
                            element['position']['end'] >= position)
                        .toList();
                    if (line.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingLarge),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "${line[0]['month']}月",
                              style: const TextStyle(fontSize: 30),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    "${line[0]['day'].toString().padLeft(2, "0")}日"),
                                Text("${line[0]['year']}"),
                              ],
                            )
                          ],
                        ),
                      );
                    } else {
                      return const Placeholder(
                        child: Center(
                          child: Text('[x]'),
                        ),
                      );
                    }
                  },
                  labelConstraints: const BoxConstraints(
                      minHeight: 60,
                      maxHeight: 60,
                      minWidth: 140,
                      maxWidth: 140),
                  controller: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    itemBuilder: (context, i) {
                      return buildTimelineItem(timeline.value[i]);
                    },
                    itemCount: timeline.value.length,
                  ),
                )
              : const Center(
                  child: Text("无项目"),
                ),
    );
  }
}
