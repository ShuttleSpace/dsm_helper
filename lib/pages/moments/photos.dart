import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/util/format_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/moments_api.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:flutter/material.dart';

class Photos extends StatefulWidget {
  final Map album;
  final Object? tag;
  const Photos(this.album, {super.key, this.tag});
  @override
  PhotosState createState() => PhotosState();
}

class PhotosState extends State<Photos> {
  double photoWidth = 0;
  List photos = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await MomentsApi.photos(albumId: widget.album['id']);
    if (res['success']) {
      setState(() {
        photos = res['data']['list'];
      });
    }
  }

  Widget _buildPhotoItem(photo) {
    String thumbUrl =
        '${connectionStore.baseUrl}/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${connectionStore.version >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(TransparentPageRoute(
          pageBuilder: (context, _, __) {
            return ImagePreview(
              photos
                  .map((photo) =>
                      '${connectionStore.baseUrl}/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="xl"&api="SYNO.${connectionStore.version >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}')
                  .toList(),
              photos.indexOf(photo),
              tag: "photo-ablum-${photo['additional']['thumbnail']['unit_id']}",
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
              tag: "photo-ablum-${photo['additional']['thumbnail']['unit_id']}",
              child: CupertinoExtendedImage(
                // "http://pan.fmtol.com:5000/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key=%22${photo['additional']['thumbnail']['cache_key']}%22&type=%22unit%22&size=%22sm%22&api=%22SYNO.${HttpUtil.version == 7 ? "Foto" : "Photo"}.Thumbnail%22&method=%22get%22&version=1&_sid=${HttpUtil.sid}",
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
                      "${FormatUtil.timeLong(5235)['hours'].toString().padLeft(2, "0")}:${FormatUtil.timeLong(5235)['minutes'].toString().padLeft(2, "0")}:${FormatUtil.timeLong(5235)['seconds'].toString().padLeft(2, "0")}",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              leading: AppBackButton(
                context,
                bevel: 0,
              ),
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "${widget.album['name']}",
                  style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      shadows: const [
                        BoxShadow(
                            color: Colors.white,
                            offset: Offset(1, 1),
                            blurRadius: 5,
                            spreadRadius: 5)
                      ]),
                ),
                centerTitle: true,
                background: Hero(
                  tag: widget.tag ?? '',
                  child: CupertinoExtendedImage(
                    '${connectionStore.baseUrl}/webapi/entry.cgi?id=${widget.album['additional']['thumbnail']['unit_id']}&cache_key="${widget.album['additional']['thumbnail']['cache_key']}"&type="unit"&size="xl"&api="SYNO.${connectionStore.version >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}',
                    fit: BoxFit.cover,
                    height: 200,
                    placeholder: CupertinoExtendedImage(
                      '${connectionStore.baseUrl}/webapi/entry.cgi?id=${widget.album['additional']['thumbnail']['unit_id']}&cache_key="${widget.album['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${connectionStore.version >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              expandedHeight: 200.0,
            )
          ];
        },
        body: ListView(
          padding: const EdgeInsets.only(top: 2),
          children: [
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: photos.isEmpty
                  ? List.generate(widget.album['item_count'], (index) {
                      return Container(
                        color: Colors.grey,
                        width: photoWidth,
                        height: photoWidth,
                      );
                    })
                  : photos.map((item) {
                      return _buildPhotoItem(item);
                    }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
