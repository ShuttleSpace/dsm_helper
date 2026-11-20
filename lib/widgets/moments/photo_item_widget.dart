import 'package:garden/extensions/int.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class PhotoItemWidget extends StatelessWidget {
  final Map photo;
  final List photos;
  final double photoWidth;

  const PhotoItemWidget({
    super.key,
    required this.photo,
    required this.photos,
    required this.photoWidth,
  });

  @override
  Widget build(BuildContext context) {
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
        '${connectionStore.baseUri}/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${connectionStore.dsmVersion.watch(context) >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(TransparentPageRoute(
          pageBuilder: (context, _, __) {
            return ImagePreview(
              photos
                  .map((photo) =>
                      '${connectionStore.baseUri}/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="xl"&api="SYNO.${connectionStore.dsmVersion >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}')
                  .toList(),
              photos.indexOf(photo),
              tag: "photo-${photo['additional']['thumbnail']['unit_id']}",
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
              tag: "photo-${photo['additional']['thumbnail']['unit_id']}",
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
}
