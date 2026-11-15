import 'package:garden/api/dsm_api.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/moments/moments_content_tab.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Moments extends HookWidget {
  const Moments({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = useSignal(0);
    final scrollController = useScrollController();
    final timeline = useSignal<List>([]);
    final album = useSignal<List>([]);
    final recentlyAdd = useSignal<List>([]);
    final videos = useSignal<List>([]);
    final shares = useSignal<List>([]);
    final geocoding = useSignal<List>([]);
    final general = useSignal<List>([]);
    final width = MediaQuery.sizeOf(context).width;
    final double photoWidth = (width - 6) / 4;
    final double albumWidth = (width - 60) / 2;
    final loadingTimeline = useSignal(true);
    final loadingAlbum = useSignal(true);
    final loadingShares = useSignal(true);

    getData() async {
      var res = await dsmFotoBrowseTimeline();
      if (context.mounted) {
        timeline.value = [];
        if (connectionStore.dsmVersion.value == 7) {
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

    getAlbum() async {
      var res = await dsmFotoBrowseAlbumListMoments();
      if (context.mounted) {
        album.value = res['list'];
        loadingAlbum.value = false;
      }
    }

    getRecently() async {
      var res =
          await dsmFotoBrowsePhotoList(category: "RecentlyAdded", limit: 4);
      if (context.mounted) {
        recentlyAdd.value = res["list"];
      }
    }

    getShares() async {
      var res = await dsmFotoBrowseAlbumListMoments(shared: true, limit: 4);
      if (context.mounted) {
        shares.value = res["list"];
        loadingShares.value = false;
      }
    }

    getGeocoding() async {
      var res = await dsmFotoBrowseGeocoding(limit: 4);
      if (context.mounted) {
        geocoding.value = res["list"];
      }
    }

    getGeneral({bool isTeam = false}) async {
      var res = await dsmFotoBrowseGeneral(limit: 4, isTeam: isTeam);
      if (context.mounted) {
        general.value = res["list"];
      }
    }

    getVideos() async {
      var res = await dsmFotoBrowsePhotoList(type: "video", limit: 4);
      if (context.mounted) {
        videos.value = res["list"];
      }
    }

    useEffect(() {
      getData();
      getAlbum();
      getRecently();
      getVideos();
      getShares();
      if (connectionStore.dsmVersion.value == 7) {
        Log.debug("DSM 版本为7");
        getGeocoding();
        getGeneral();
      }
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: DropdownMenu(
          enableFilter: false,
          enableSearch: false,
          enabled: false,
          initialSelection: currentIndex.value,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 0, label: '图片'),
            DropdownMenuEntry(value: 1, label: '相册'),
            DropdownMenuEntry(value: 2, label: '共享'),
          ],
          onSelected: (value) {
            currentIndex.value = value ?? 0;
          },
        ),
      ),
      body: MomentsContentTab(
        currentIndex: currentIndex.value,
        loadingTimeline: loadingTimeline.value,
        loadingAlbum: loadingAlbum.value,
        loadingShares: loadingShares.value,
        timeline: timeline.value,
        album: album.value,
        shares: shares.value,
        geocoding: geocoding.value,
        general: general.value,
        videos: videos.value,
        recentlyAdd: recentlyAdd.value,
        scrollController: scrollController,
        photoWidth: photoWidth,
        albumWidth: albumWidth,
        onTabChanged: (index) {
          currentIndex.value = index;
        },
      ),
    );
  }
}
