import 'package:flutter/cupertino.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class SelectAlbum extends HookWidget {
  final bool multi;
  final bool folder;
  final List<AssetPathEntity>? selected;
  const SelectAlbum(
      {super.key, this.multi = false, this.folder = true, this.selected});

  @override
  Widget build(BuildContext context) {
    final albums = useSignal<List<AssetPathEntity>>([]);
    final selectedAlbums = useSignal<List<AssetPathEntity>>(
        selected != null ? List.of(selected!) : []);

    getData() async {
      List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
      albums.value = list;
      if (albums.value.isEmpty) {
        UiUtil.toast('not found album!');
      }
    }

    Widget buildAlbumItem(AssetPathEntity album) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
        child: Opacity(
          opacity: 1,
          child: OutlinedButton(
            onPressed: () async {
              if (multi) {
                if (album.isAll) {
                  selectedAlbums.value = [album];
                } else {
                  final selected = selectedAlbums.value
                      .where((element) => !element.isAll)
                      .toList();
                  if (selected.contains(album)) {
                    selected.remove(album);
                  } else {
                    selected.add(album);
                  }
                  selectedAlbums.value = selected;
                }
              } else {
                selectedAlbums.value = [album];
              }
            },
            // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: FutureBuilder<int>(
                    future: album.assetCountAsync,
                    builder: (context, snapshot) {
                      return Text(
                        "${album.name} (${snapshot.data})",
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: selectedAlbums.value.contains(album)
                          ? const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppColors.primaryAction,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return SizedBox(

      width: double.infinity,

      child: Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                height: 45,
                color: Theme.of(context).scaffoldBackgroundColor,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingSmall + 2),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(selectedAlbums.value);
                        },
                        child: const Text(
                          "完成",
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: albums.value.map(buildAlbumItem).toList(),
              )),
            ],
          ),
        ),
      ),
    ),

    );
  }
}
