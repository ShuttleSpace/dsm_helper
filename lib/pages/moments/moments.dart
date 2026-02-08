import 'package:garden/api/dsm_api.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/moments/moments_content_tab.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class Moments extends StatefulWidget {
  const Moments({super.key});

  @override
  MomentsState createState() => MomentsState();
}

class MomentsState extends State<Moments> {
  int currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  List timeline = [];
  List category = [];
  List album = [];
  List recentlyAdd = [];
  List videos = [];
  List shares = [];
  List geocoding = [];
  List general = [];
  double photoWidth = 0;
  double albumWidth = 0;
  bool loadingTimeline = true;
  bool loadingAlbum = true;
  bool loadingShares = true;

  @override
  void initState() {
    getData();
    // getCategory();
    getAlbum();
    getRecently();
    getVideos();
    getShares();
    if (connectionStore.dsmVersion.watch(context) == 7) {
      Log.debug("DSM 版本为7");
      getGeocoding();
      getGeneral();
    }

    super.initState();
  }

  getData() async {
    var res = await dsmFotoBrowseTimeline();
    if (mounted) {
      setState(() {
        timeline = [];
        if (connectionStore.dsmVersion.watch(context) == 7) {
          for (var section in res['section']) {
            timeline.addAll(section['list']);
          }
        } else {
          timeline = res['list'];
        }

        for (int i = 0; i < timeline.length; i++) {
          int lines = (timeline[i]['item_count'] / 4).ceil();
          double height = 40 + lines * photoWidth + (lines - 1) * 2;
          timeline[i]['position'] = {};
          if (i == 0) {
            timeline[i]['position']['start'] = 0;
            timeline[i]['position']['end'] = height;
          } else {
            timeline[i]['position']['start'] =
                timeline[i - 1]['position']['end'];
            timeline[i]['position']['end'] =
                timeline[i]['position']['start'] + height;
          }
        }
        loadingTimeline = false;
      });
    }
  }

  getCategory() async {
    var res = await dsmFotoBrowseCategory();
    if (mounted) {
      setState(() {
        category = res['list'] ?? [];
      });
    }
  }

  getAlbum() async {
    var res = await dsmFotoBrowseAlbumListMoments();
    if (mounted) {
      setState(() {
        album = res['list'];
        loadingAlbum = false;
      });
    }
  }

  getRecently() async {
    var res = await dsmFotoBrowsePhotoList(category: "RecentlyAdded", limit: 4);
    if (mounted) {
      setState(() {
        recentlyAdd = res["list"];
      });
    }
  }

  getShares() async {
    var res = await dsmFotoBrowseAlbumListMoments(shared: true, limit: 4);
    if (mounted) {
      setState(() {
        shares = res["list"];
        loadingShares = false;
      });
    }
  }

  getGeocoding() async {
    var res = await dsmFotoBrowseGeocoding(limit: 4);
    if (mounted) {
      setState(() {
        geocoding = res["list"];
      });
    }
  }

  getGeneral({bool isTeam = false}) async {
    var res = await dsmFotoBrowseGeneral(limit: 4, isTeam: isTeam);
    if (mounted) {
      setState(() {
        general = res["list"];
      });
    }
  }

  getVideos() async {
    var res = await dsmFotoBrowsePhotoList(type: "video", limit: 4);
    if (mounted) {
      setState(() {
        videos = res["list"];
      });
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: DropdownMenu(
          enableFilter: false,
          enableSearch: false,
          enabled: false,
          initialSelection: currentIndex,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 0, label: '图片'),
            DropdownMenuEntry(value: 1, label: '相册'),
            DropdownMenuEntry(value: 2, label: '共享'),
          ],
          onSelected: (value) {
            _onTabChanged(value ?? 0);
          },
        ),
      ),
      body: MomentsContentTab(
        currentIndex: currentIndex,
        loadingTimeline: loadingTimeline,
        loadingAlbum: loadingAlbum,
        loadingShares: loadingShares,
        timeline: timeline,
        album: album,
        shares: shares,
        geocoding: geocoding,
        general: general,
        videos: videos,
        recentlyAdd: recentlyAdd,
        scrollController: _scrollController,
        photoWidth: photoWidth,
        albumWidth: albumWidth,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}
