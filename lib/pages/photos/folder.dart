import 'package:garden/models/photos/folder_model.dart';
import 'package:garden/pages/photos/widgets/photo_item_widget.dart';
import 'package:garden/pages/photos/widgets/thumbnail_card.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/util/log.dart';

class Folder extends StatefulWidget {
  const Folder(this.isTeam, {super.key});
  final bool isTeam;
  @override
  State<Folder> createState() => FolderState();
}

class FolderState extends State<Folder> {
  ScrollController pathScrollController = ScrollController();
  bool loading = true;
  List<FolderModel> folders = [];
  bool isTeam = false;
  double folderWidth = 0;
  @override
  void initState() {
    isTeam = widget.isTeam;
    getData(isTeam: isTeam);
    super.initState();
  }

  Future getData({bool isTeam = false}) async {
    this.isTeam = isTeam;
    try {
      folders = [];
      FolderModel root = await FolderModel.fetch(
          additional: ['access_permission'], isTeam: isTeam);
      folders.add(root);
      fetchFolderDetail(root);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future fetchFolderDetail(FolderModel folder) async {
    setState(() {
      loading = true;
    });
    await Future.wait([
      folder.fetchFolders(
          additional: isTeam
              ? [
                  "sharing_info",
                  "access_permission",
                  "thumbnail",
                  "password_verified"
                ]
              : ["thumbnail"],
          isTeam: isTeam),
      folder.fetchPhotos(additional: [
        "thumbnail",
        "resolution",
        "orientation",
        "video_convert",
        "video_meta"
      ], isTeam: isTeam),
    ]);
    Future.delayed(const Duration(milliseconds: 200)).then((_) {
      Log.info(
          "fetch folder detail : ${pathScrollController.position.maxScrollExtent}");
      pathScrollController.animateTo(
          pathScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.ease);
    });
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    folderWidth = MediaQuery.sizeOf(context).width / 4;
    return Stack(
      children: [
        if (folders.isNotEmpty)
          Column(
            children: [
              Container(
                height: 30,
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                child: ListView.separated(
                  controller: pathScrollController,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        fetchFolderDetail(folders[i]);
                        setState(() {
                          folders = folders.sublist(0, i + 1);
                        });
                      },
                      child: Text(
                        folders[i].lastName == "/"
                            ? "全部"
                            : folders[i].lastName ?? '',
                        style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: i == folders.length - 1
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    );
                  },
                  itemCount: folders.length,
                  separatorBuilder: (context, i) {
                    return const Text(
                      ">",
                      style: TextStyle(color: AppColors.greyDark),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge),
                  children: [
                    Wrap(
                      runSpacing: 20,
                      spacing: 20,
                      children: [
                        ...folders.last.folders.map((folder) {
                          return _buildFolderItem(folder);
                        }),
                        ...folders.last.photos.map((photo) {
                          return PhotoItemWidget(
                            photo,
                            folders.last.photos,
                            width: folderWidth,
                            isTeam: isTeam,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (loading)
          const Center(
            child: CupertinoActivityIndicator(
              radius: 14,
            ),
          )
      ],
    );
  }

  Widget _buildFolderItem(FolderModel folder) {
    return GestureDetector(
      onTap: () {
        setState(() {
          folders.add(folder);
        });
        fetchFolderDetail(folder);
      },
      child: SizedBox(
        width: folderWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThumbnailCard(
              folder.additional?.thumbnail ?? [],
              width: folderWidth,
              folderId: folder.id?.toInt(),
              isTeam: isTeam,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              "${folder.lastName}",
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
