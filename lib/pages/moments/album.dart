import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/moments/photos.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Album extends HookWidget {
  final bool shared;
  final String title;
  const Album(this.title, {super.key, this.shared = false});

  @override
  Widget build(BuildContext context) {
    final loadingAlbum = useSignal(true);
    final album = useSignal<List>([]);
    final dsmVersion = useSignalValue(connectionStore.dsmVersion);
    final sid = useSignalValue(connectionStore.sid);
    final baseUri = useSignalValue(connectionStore.baseUri);
    const double albumWidth = 0;

    getAlbum() async {
      var res = await dsmFotoBrowseAlbumListMoments(shared: true);
      if (context.mounted) {
        album.value = res['list'];
        loadingAlbum.value = false;
      }
    }

    Widget buildAlbumItem(albumItem) {
      String thumbUrl =
          '$baseUri/webapi/entry.cgi?id=${albumItem['additional']['thumbnail']['unit_id']}&cache_key="${albumItem['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=$sid';
      String tag = "album-${albumItem['additional']['thumbnail']['unit_id']}";
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return Photos(albumItem, tag: tag);
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
                tag: "album-${albumItem['additional']['thumbnail']['unit_id']}",
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
              "${albumItem['name']}",
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
            ),
            Text(
              "${albumItem['item_count']}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    useEffect(() {
      getAlbum();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          context,
        ),
        title: Text(title),
      ),
      body: loadingAlbum.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : album.value.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      runSpacing: 20,
                      spacing: 20,
                      children: [
                        ...album.value.map(buildAlbumItem),
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
