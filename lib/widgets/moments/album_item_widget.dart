import 'package:garden/pages/moments/photos.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AlbumItemWidget extends StatelessWidget {
  final Map album;
  final double albumWidth;
  final VoidCallback? onTap;

  const AlbumItemWidget({
    super.key,
    required this.album,
    required this.albumWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String thumbUrl =
        '${connectionStore.baseUri}/webapi/entry.cgi?id=${album['additional']['thumbnail']['unit_id']}&cache_key="${album['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${connectionStore.dsmVersion.watch(context) >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}';
    String tag = "album-${album['additional']['thumbnail']['unit_id']}";

    return GestureDetector(
      onTap: onTap ??
          () {
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
}
