import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/moments_api.dart';
import 'package:garden/widgets/moments/moments_content_tab.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

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
    if (connectionStore.version == 7) {
      debugPrint("DSM 版本为7");
      getGeocoding();
      getGeneral();
    }

    super.initState();
  }

  getData() async {
    var res = await MomentsApi.timeline();
    if (res['success'] && mounted) {
      setState(() {
        timeline = [];
        if (connectionStore.version == 7) {
          for (var section in res['data']['section']) {
            timeline.addAll(section['list']);
          }
        } else {
          timeline = res['data']['list'];
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
        setState(() {
          loadingTimeline = false;
        });
      });
    }
  }

  getCategory() async {
    var res = await MomentsApi.category();
    if (res['success'] && mounted) {
      setState(() {
        category = res['data'];
      });
    }
  }

  getAlbum() async {
    var res = await MomentsApi.album();
    if (res['success'] && mounted) {
      setState(() {
        album = res['data']['list'];
        loadingAlbum = false;
      });
    }
  }

  getRecently() async {
    var res = await MomentsApi.photos(category: "RecentlyAdded", limit: 4);
    if (res['success'] && mounted) {
      setState(() {
        recentlyAdd = res['data']["list"];
      });
    }
  }

  getShares() async {
    var res = await MomentsApi.album(shared: true, limit: 4);
    if (res['success'] && mounted) {
      setState(() {
        shares = res['data']["list"];
        loadingShares = false;
      });
    }
  }

  getGeocoding() async {
    var res = await MomentsApi.geocoding(limit: 4);
    if (res['success'] && mounted) {
      setState(() {
        geocoding = res['data']["list"];
      });
    }
  }

  getGeneral({bool isTeam = false}) async {
    var res = await MomentsApi.general(limit: 4, isTeam: isTeam);
    if (res['success'] && mounted) {
      setState(() {
        general = res['data']["list"];
      });
    }
  }

  getVideos() async {
    var res = await MomentsApi.photos(type: "video", limit: 4);
    if (res['success'] && mounted) {
      setState(() {
        videos = res['data']["list"];
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
