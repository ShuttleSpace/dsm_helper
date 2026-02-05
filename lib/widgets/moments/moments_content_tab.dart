import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:garden/pages/moments/timeline.dart';
import 'package:garden/widgets/moments/album_item_widget.dart';
import 'package:garden/widgets/moments/category_card_widget.dart';
import 'package:garden/widgets/moments/timeline_item_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/constants/app_constants.dart';

class MomentsContentTab extends StatelessWidget {
  final int currentIndex;
  final bool loadingTimeline;
  final bool loadingAlbum;
  final bool loadingShares;
  final List timeline;
  final List album;
  final List shares;
  final List geocoding;
  final List general;
  final List videos;
  final List recentlyAdd;
  final ScrollController scrollController;
  final double photoWidth;
  final double albumWidth;
  final Function(int)? onTabChanged;

  const MomentsContentTab({
    super.key,
    required this.currentIndex,
    required this.loadingTimeline,
    required this.loadingAlbum,
    required this.loadingShares,
    required this.timeline,
    required this.album,
    required this.shares,
    required this.geocoding,
    required this.general,
    required this.videos,
    required this.recentlyAdd,
    required this.scrollController,
    required this.photoWidth,
    required this.albumWidth,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: [
        _buildTimelineTab(context),
        _buildAlbumTab(context),
        _buildSharesTab(context),
      ],
    );
  }

  Widget _buildTimelineTab(BuildContext context) {
    if (loadingTimeline) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 14,
        ),
      );
    }

    if (timeline.isNotEmpty) {
      return DraggableScrollbar.semicircle(
        labelTextBuilder: (position) {
          var line = timeline
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
                      Text("${line[0]['day'].toString().padLeft(2, "0")}日"),
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
            minHeight: 60, maxHeight: 60, minWidth: 140, maxWidth: 140),
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          itemBuilder: (context, i) {
            return TimelineItemWidget(
              line: timeline[i],
              photoWidth: photoWidth,
            );
          },
          itemCount: timeline.length,
        ),
      );
    } else {
      return const Center(
        child: Text("无项目"),
      );
    }
  }

  Widget _buildAlbumTab(BuildContext context) {
    if (loadingAlbum) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 14,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          runSpacing: 20,
          spacing: 20,
          children: [
            if (geocoding.isNotEmpty)
              CategoryCardWidget(
                photos: geocoding,
                title: "位置",
                albumWidth: albumWidth,
              ),
            if (general.isNotEmpty)
              CategoryCardWidget(
                photos: general,
                title: "标签",
                albumWidth: albumWidth,
              ),
            CategoryCardWidget(
              photos: videos,
              title: "视频",
              albumWidth: albumWidth,
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Timeline(
                      "视频",
                      category: "Timeline",
                      type: "video",
                    );
                  },
                ));
              },
            ),
            CategoryCardWidget(
              photos: recentlyAdd,
              title: "最近添加的",
              albumWidth: albumWidth,
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Timeline(
                      "最近添加的",
                      category: "RecentlyAdded",
                    );
                  },
                ));
              },
            ),
          ],
        ),
        album.isNotEmpty
            ? Wrap(
                runSpacing: 20,
                spacing: 20,
                children: [
                  ...album.map((album) {
                    return AlbumItemWidget(
                      album: album,
                      albumWidth: albumWidth,
                    );
                  }),
                ],
              )
            : const SizedBox(
                height: 500,
                child: Center(
                  child: Text("无手动创建的相册"),
                ),
              ),
      ],
    );
  }

  Widget _buildSharesTab(BuildContext context) {
    if (loadingShares) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 14,
        ),
      );
    }

    if (shares.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          runSpacing: 20,
          spacing: 20,
          children: [
            ...shares.map((album) {
              return AlbumItemWidget(
                album: album,
                albumWidth: albumWidth,
              );
            }),
          ],
        ),
      );
    } else {
      return const SizedBox(
        height: 500,
        child: Center(
          child: Text("无手动创建的相册"),
        ),
      );
    }
  }
}
