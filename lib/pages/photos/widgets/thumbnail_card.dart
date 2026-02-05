import 'package:garden/models/photos/thumbnail_model.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:flutter/material.dart';

class ThumbnailCard extends StatelessWidget {
  const ThumbnailCard(this.thumbnails,
      {super.key, required this.width, this.folderId, this.isTeam = false});
  final int? folderId;
  final List<ThumbnailModel> thumbnails;
  final double width;
  final bool isTeam;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: thumbnails.isEmpty
            ? Container(
                color: AppColors.placeholderBackgroundLight,
                child: Center(
                  child: Image.asset(
                    "assets/icons/folder_empty.png",
                    width: width / 3,
                  ),
                ),
              )
            : thumbnails.length == 1
                ? CupertinoExtendedImage(
                    thumbnails[0].thumbUrl(folderId: folderId, isTeam: isTeam),
                    width: width,
                    height: width,
                    fit: BoxFit.cover,
                    boxShape: BoxShape.rectangle,
                    placeholder: Container(
                      width: width,
                      height: width,
                      color: AppColors.placeholderBackgroundLight,
                    ),
                  )
                : thumbnails.length == 2
                    ? Column(
                        children: [
                          SizedBox(
                            width: width,
                            height: (width - 2) / 2,
                            child: CupertinoExtendedImage(
                              thumbnails[0].thumbUrl(isTeam: isTeam),
                              width: width,
                              height: (width - 2) / 2,
                              fit: BoxFit.cover,
                              boxShape: BoxShape.rectangle,
                              placeholder: Container(
                                width: width,
                                height: (width - 2) / 2,
                                color: AppColors.placeholderBackgroundLight,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          SizedBox(
                            width: width,
                            height: (width - 2) / 2,
                            child: CupertinoExtendedImage(
                              thumbnails[1].thumbUrl(isTeam: isTeam),
                              width: width,
                              height: (width - 2) / 2,
                              fit: BoxFit.cover,
                              boxShape: BoxShape.rectangle,
                              placeholder: Container(
                                width: width,
                                height: (width - 2) / 2,
                                color: AppColors.placeholderBackgroundLight,
                              ),
                            ),
                          )
                        ],
                      )
                    : thumbnails.length == 3
                        ? Wrap(
                            runSpacing: 2,
                            spacing: 2,
                            children: [
                              ...List.generate(3, (index) {
                                if (index < 2) {
                                  return CupertinoExtendedImage(
                                    thumbnails[index].thumbUrl(isTeam: isTeam),
                                    width: (width - 2) / 2,
                                    height: (width - 2) / 2,
                                    fit: BoxFit.cover,
                                    boxShape: BoxShape.rectangle,
                                    placeholder: Container(
                                      color:
                                          AppColors.placeholderBackgroundLight,
                                    ),
                                  );
                                } else {
                                  return CupertinoExtendedImage(
                                    thumbnails[index].thumbUrl(isTeam: isTeam),
                                    width: width,
                                    height: (width - 2) / 2,
                                    fit: BoxFit.cover,
                                    boxShape: BoxShape.rectangle,
                                    placeholder: Container(
                                      color:
                                          AppColors.placeholderBackgroundLight,
                                    ),
                                  );
                                }
                              })
                            ],
                          )
                        : Wrap(
                            runSpacing: 2,
                            spacing: 2,
                            children: [
                              ...List.generate(4, (index) {
                                if (index < thumbnails.length) {
                                  return CupertinoExtendedImage(
                                    thumbnails[index].thumbUrl(isTeam: isTeam),
                                    width: (width - 2) / 2,
                                    height: (width - 2) / 2,
                                    fit: BoxFit.cover,
                                    boxShape: BoxShape.rectangle,
                                    placeholder: Container(
                                      color:
                                          AppColors.placeholderBackgroundLight,
                                    ),
                                  );
                                } else {
                                  return Container(
                                    color: AppColors.placeholderBackgroundLight,
                                  );
                                }
                              })
                            ],
                          ),
      ),
    );
  }
}
