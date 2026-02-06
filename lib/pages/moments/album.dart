import 'package:garden/pages/moments/photos.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/moments_api.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class Album extends StatefulWidget {
  final bool shared;
  final String title;
  const Album(this.title, {super.key, this.shared = false});
  @override
  AlbumState createState() => AlbumState();
}

class AlbumState extends State<Album> {
  bool loadingAlbum = true;
  double albumWidth = 0;
  List album = [];
  @override
  void initState() {
    getAlbum();
    super.initState();
  }

  getAlbum() async {
    var res = await MomentsApi.album(shared: true);
    if (res['success'] && mounted) {
      setState(() {
        album = res['data']['list'];
        loadingAlbum = false;
      });
    }
  }

  Widget _buildAlbumItem(album) {
    String thumbUrl =
        '${connectionStore.baseUrl}/webapi/entry.cgi?id=${album['additional']['thumbnail']['unit_id']}&cache_key="${album['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${connectionStore.dsmVersion.watch(context) >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}';
    String tag = "album-${album['additional']['thumbnail']['unit_id']}";
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) {
            return Photos(album, tag: tag);
          },
        ));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: albumWidth,
            height: albumWidth,
            child: Hero(
              tag: "album-${album['additional']['thumbnail']['unit_id']}",
              child: CupertinoExtendedImage(
                thumbUrl,
                width: albumWidth,
                height: albumWidth,
                fit: BoxFit.cover,
                boxShape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10),
                placeholder: Container(
                  width: albumWidth,
                  height: albumWidth,
                  color: AppColors.placeholderBackgroundLight,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            "${album['name']}",
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
          ),
          Text(
            "${album['item_count']}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          context,
        ),
        title: Text(widget.title),
      ),
      body: loadingAlbum
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : album.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      runSpacing: 20,
                      spacing: 20,
                      children: [
                        ...album.map(_buildAlbumItem),
                      ],
                    )
                  ],
                )
              : const SizedBox(
                  height: 500,
                  child: Center(
                    child: Text("无手动创建的相册"),
                  ),
                ),
    );
  }
}
