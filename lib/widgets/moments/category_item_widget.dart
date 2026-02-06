import 'package:garden/theme/app_colors.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CategoryItemWidget extends StatelessWidget {
  final List photos;
  final int index;
  final double albumWidth;

  const CategoryItemWidget({
    super.key,
    required this.photos,
    required this.index,
    required this.albumWidth,
  });

  @override
  Widget build(BuildContext context) {
    double itemWidth = (albumWidth - 2) / 2;
    if (index < photos.length) {
      Map photo = photos[index];
      String thumbUrl =
          '${connectionStore.baseUrl}/webapi/entry.cgi?id=${photo['additional']['thumbnail']['unit_id']}&cache_key="${photo['additional']['thumbnail']['cache_key']}"&type="unit"&size="sm"&api="SYNO.${connectionStore.dsmVersion.watch(context) >= 7 ? "Foto" : "Photo"}.Thumbnail"&method="get"&version=1&_sid=${connectionStore.sid}';
      return SizedBox(
        width: itemWidth,
        height: itemWidth,
        child: CupertinoExtendedImage(
          thumbUrl,
          width: itemWidth,
          height: itemWidth,
          fit: BoxFit.cover,
          boxShape: BoxShape.rectangle,
          placeholder: Container(
            width: itemWidth,
            height: itemWidth,
            color: AppColors.placeholderBackgroundLight,
          ),
        ),
      );
    } else {
      return Container(
        width: itemWidth,
        height: itemWidth,
        decoration: const BoxDecoration(
          color: Colors.grey,
        ),
      );
    }
  }
}
