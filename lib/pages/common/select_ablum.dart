import 'package:flutter/cupertino.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class SelectAlbum extends StatefulWidget {
  final bool multi;
  final bool folder;
  final List<AssetPathEntity>? selected;
  const SelectAlbum(
      {super.key, this.multi = false, this.folder = true, this.selected});
  @override
  SelectAlbumState createState() => SelectAlbumState();
}

class SelectAlbumState extends State<SelectAlbum> {
  List<AssetPathEntity> albums = [];
  List<AssetPathEntity> selectedAlbums = [];
  bool success = true;
  @override
  void initState() {
    if (widget.selected != null) {
      setState(() {
        selectedAlbums = widget.selected!;
      });
    }
    getData();
    super.initState();
  }

  getData() async {
    List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
    setState(() {
      albums = list;
      if (albums.isEmpty) {
        UiUtil.toast('not found album!');
      }
    });
  }

  Widget _buildAlbumItem(AssetPathEntity album) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: Opacity(
        opacity: 1,
        child: OutlinedButton(
          onPressed: () async {
            setState(() {
              if (widget.multi) {
                if (album.isAll) {
                  selectedAlbums = [album];
                } else {
                  selectedAlbums = selectedAlbums
                      .where((element) => !element.isAll)
                      .toList();
                  if (selectedAlbums.contains(album)) {
                    selectedAlbums.remove(album);
                  } else {
                    selectedAlbums.add(album);
                  }
                }
              } else {
                selectedAlbums = [album];
              }
            });
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
                    child: selectedAlbums.contains(album)
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

  @override
  Widget build(BuildContext context) {
    return Material(
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
                          Navigator.of(context).pop(selectedAlbums);
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
                children: albums.map(_buildAlbumItem).toList(),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
