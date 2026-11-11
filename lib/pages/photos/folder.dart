import 'package:garden/models/photos/folder_model.dart';
import 'package:garden/pages/photos/widgets/photo_item_widget.dart';
import 'package:garden/pages/photos/widgets/thumbnail_card.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/util/log.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Folder extends HookWidget {
  const Folder(this.isTeam, {super.key});
  final bool isTeam;

  @override
  Widget build(BuildContext context) {
    final pathScrollController = useScrollController();
    final loading = useSignal(true);
    final folders = useSignal<List<FolderModel>>([]);
    final folderWidth = MediaQuery.sizeOf(context).width / 4;

    Future fetchFolderDetail(FolderModel folder) async {
      loading.value = true;
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
      loading.value = false;
    }

    Future getData() async {
      try {
        folders.value = [];
        FolderModel root = await FolderModel.fetch(
            additional: ['access_permission'], isTeam: isTeam);
        folders.value = [...folders.value, root];
        fetchFolderDetail(root);
      } catch (e) {
        Log.debug(e.toString());
      }
    }

    Widget buildFolderItem(FolderModel folder) {
      return GestureDetector(
        onTap: () {
          folders.value = [...folders.value, folder];
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

    useEffect(() {
      getData();
      return null;
    }, [isTeam]);

    return Stack(
      children: [
        if (folders.value.isNotEmpty)
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
                        fetchFolderDetail(folders.value[i]);
                        folders.value = folders.value.sublist(0, i + 1);
                      },
                      child: Text(
                        folders.value[i].lastName == "/"
                            ? "全部"
                            : folders.value[i].lastName ?? '',
                        style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: i == folders.value.length - 1
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    );
                  },
                  itemCount: folders.value.length,
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
                        ...folders.value.last.folders.map((folder) {
                          return buildFolderItem(folder);
                        }),
                        ...folders.value.last.photos.map((photo) {
                          return PhotoItemWidget(
                            photo,
                            folders.value.last.photos,
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
        if (loading.value)
          const Center(
            child: CupertinoActivityIndicator(
              radius: 14,
            ),
          )
      ],
    );
  }
}
