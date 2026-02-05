import 'package:garden/models/photos/album_model.dart';
import 'package:garden/models/photos/photo_model.dart';
import 'package:garden/pages/photos/widgets/photo_item_widget.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:garden/theme/app_colors.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage(this.album, {super.key, this.isTeam = false});
  final AlbumModel album;
  final bool isTeam;
  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  double photoWidth = 0;
  List<PhotoModel> photos = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    photos = await PhotoModel.fetch(
      additional: [
        "thumbnail",
        "resolution",
        "orientation",
        "video_convert",
        "video_meta",
        "provider_user_id"
      ],
      albumId: widget.album.id?.toInt(),
    );
    setState(() {});
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
                  "${widget.album.name}",
                  style: TextStyle(
                      color:
                          Theme.of(context).appBarTheme.titleTextStyle?.color,
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
                  tag: widget.album.additional?.thumbnail ?? '',
                  child: CupertinoExtendedImage(
                    widget.album.additional?.thumbnail?.thumbUrl(size: 'lg') ??
                        '',
                    fit: BoxFit.cover,
                    height: 200,
                    placeholder: CupertinoExtendedImage(
                      widget.album.additional?.thumbnail
                              ?.thumbUrl(size: 'sm') ??
                          '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              expandedHeight: 200.0,
            )
          ];
        },
        body: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 2, crossAxisSpacing: 2),
          itemBuilder: (context, i) {
            if (photos.isNotEmpty) {
              return PhotoItemWidget(
                photos[i],
                photos,
                showName: false,
                width: photoWidth,
                isTeam: widget.isTeam,
              );
            } else {
              return Container(
                color: AppColors.placeholderBackgroundLight,
                width: photoWidth,
                height: photoWidth,
              );
            }
          },
          itemCount: photos.isNotEmpty
              ? photos.length.toInt()
              : widget.album.itemCount?.toInt(),
        ),
        // body: ListView(
        //   padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        //   children: [
        //     Wrap(
        //       spacing: 2,
        //       runSpacing: 2,
        //       children: photos.length == 0
        //           ? List.generate(widget.album.itemCount, (index) {
        //               return Container(
        //                 color: AppColors.placeholderBackgroundLight,
        //                 width: photoWidth,
        //                 height: photoWidth,
        //               );
        //             })
        //           : photos.map((item) {
        //               return PhotoItemWidget(
        //                 item,
        //                 photos,
        //                 showName: false,
        //                 width: photoWidth,
        //                 isTeam: widget.isTeam,
        //               );
        //             }).toList(),
        //     ),
        //     SizedBox(
        //       height: 20,
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
