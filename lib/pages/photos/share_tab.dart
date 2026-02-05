import 'package:garden/models/photos/album_model.dart';
import 'package:garden/pages/photos/album_page.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

class ShareTab extends StatefulWidget {
  const ShareTab({super.key});

  @override
  State<ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends State<ShareTab> {
  bool loading = true;
  List<AlbumModel> albums = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    albums = await AlbumModel.fetch(
        additional: ["thumbnail", "sharing_info"],
        shared: true,
        sortBy: 'share_modify_time');
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(
            child: CupertinoActivityIndicator(
              radius: 14,
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge),
            itemBuilder: (context, i) {
              AlbumModel e = albums[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return AlbumPage(e);
                  }));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall + 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Hero(
                          tag: e.additional?.thumbnail ?? '',
                          child: CupertinoExtendedImage(
                            e.additional?.thumbnail?.thumbUrl() ?? '',
                            width: MediaQuery.sizeOf(context).width - 40,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: AppColors.placeholderBackgroundLight,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Container(
                            width: MediaQuery.sizeOf(context).width - 40,
                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black26],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: DefaultTextStyle(
                              style: const TextStyle(color: Colors.white),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name ?? '',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      if (e.shared == true) ...[
                                        if (e.additional?.sharingInfo
                                                ?.enablePassword ==
                                            true)
                                          const Icon(
                                            CupertinoIcons.lock,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        Text(e.shareText),
                                        const Text("，"),
                                      ],
                                      Text("${e.itemCount}张照片"),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            itemCount: albums.length,
          );
  }
}
