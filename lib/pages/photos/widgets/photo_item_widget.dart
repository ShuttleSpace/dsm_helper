import 'package:garden/models/photos/photo_model.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PhotoItemWidget extends StatelessWidget {
  const PhotoItemWidget(this.photo, this.photos,
      {super.key, this.isTeam, this.showName = true, required this.width});
  final PhotoModel photo;
  final List<PhotoModel> photos;
  final bool? isTeam;
  final double width;
  final bool? showName;
  @override
  Widget build(BuildContext context) {
    Log.info('PhtoItemWidget: $width');
    return GestureDetector(
      onTap: () {
        if (photo.type == 'video') {
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return VideoPlayerPage(
              url: photo.videoUrl(isTeam: isTeam ?? false),
              cover: photo.thumbUrl(isTeam: isTeam ?? false),
            );
          }));
        } else {
          Navigator.of(context).push(TransparentPageRoute(
            pageBuilder: (context, _, __) {
              return ImagePreview(
                photos
                    .map((photo) =>
                        photo.thumbUrl(size: 'xl', isTeam: isTeam ?? false))
                    .toList(),
                photos.indexOf(photo),
                tag: photo,
              );
            },
          ));
        }
      },
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: photo,
                  child: CupertinoExtendedImage(
                    photo.thumbUrl(isTeam: isTeam ?? false),
                    width: width,
                    height: width,
                    fit: BoxFit.cover,
                    boxShape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    placeholder: Container(
                      color: AppColors.placeholderBackgroundLight,
                    ),
                  ),
                ),
                if (photo.type == "video")
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
                          "${photo.additional?.videoMeta?.hours.toString().padLeft(2, "0")}:${photo.additional?.videoMeta?.minutes.toString().padLeft(2, "0")}:${photo.additional?.videoMeta?.seconds.toString().padLeft(2, "0")}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  )
              ],
            ),
            if (showName == true)
              Text(
                photo.filename ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
