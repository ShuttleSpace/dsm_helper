import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Photos extends HookWidget {
  final Map album;
  final Object? tag;
  const Photos(this.album, {super.key, this.tag});

  @override
  Widget build(BuildContext context) {
    final photos = useSignal<List>([]);
    final dsmVersion = useSignalValue(connectionStore.dsmVersion);
    final sid = useSignalValue(connectionStore.sid);
    final baseUri = useSignalValue(connectionStore.baseUri);
    const double photoWidth = 0;

    getData() async {
      var res = await dsmFotoBrowsePhotoList(albumId: album['id']);
      photos.value = res['list'];
    }

    Widget buildPhotoItem(photo) {
      String thumbUrl =
          '$baseUri/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=$sid';
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(TransparentPageRoute(
            pageBuilder: (context, _, __) {
              return ImagePreview(
                photos.value
                    .map((photo) =>
                        '$baseUri/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="xl"&api="SYNO.${dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=$sid')
                    .toList(),
                photos.value.indexOf(photo),
                tag:
                    "photo-ablum-${photo['additional']['thumbnail']['unit_id']}",
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
                    "photo-ablum-${photo['additional']['thumbnail']['unit_id']}",
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
                        "${5235.formatTime()['hours'].toString().padLeft(2, "0")}:${5235.formatTime()['minutes'].toString().padLeft(2, "0")}:${5235.formatTime()['seconds'].toString().padLeft(2, "0")}",
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

    useEffect(() {
      getData();
      return null;
    }, const []);

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
                  "${album['name']}",
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
                  tag: tag ?? '',
                  child: CupertinoExtendedImage(
                    '$baseUri/webapi/entry.cgi?id=${album['additional']['thumbnail']['unit_id']}&cache_key="${album['additional']['thumbnail']['cache_key']}"&type="unit"&size="xl"&api="SYNO.${dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=$sid',
                    fit: BoxFit.cover,
                    height: 200,
                    placeholder: CupertinoExtendedImage(
                      '$baseUri/webapi/entry.cgi?id=${album['additional']['thumbnail']['unit_id']}&cache_key="${album['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=$sid',
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
              children: photos.value.isEmpty
                  ? List.generate(album['item_count'], (index) {
                      return Container(
                        color: Colors.grey,
                        width: photoWidth,
                        height: photoWidth,
                      );
                    })
                  : photos.value.map((item) {
                      return buildPhotoItem(item);
                    }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
