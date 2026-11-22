import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/name_input_dialog.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Favorite extends HookWidget {
  final Function callback;
  const Favorite(this.callback, {super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteLoading = useSignal(true);
    final favorites = useSignal<List>([]);

    getData() async {
      favoriteLoading.value = true;
      try {
        final data = await dsmFileStationFavoriteListForPage();
        favorites.value = data['favorites'] ?? [];
      } catch (e) {
        // 旧层失败时保持空列表。
      } finally {
        favoriteLoading.value = false;
      }
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    Widget buildFavoriteItem(favorite) {
      return InkWell(
        onTap: () {
          if (favorite['status'] == "broken") {
            UiUtil.toast("文件或目录不存在");
          } else {
            Navigator.of(context).pop(favorite['path']);
            callback(favorite['path']);
          }
        },
        child: Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const FileIcon(
                  FileTypeEnum.folder,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(child: Text(favorite['name'])),
                const SizedBox(
                  width: 10,
                ),
                OutlinedButton(
                  onPressed: () {
                    UiUtil.vibrate(FeedbackType.light);
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) {
                        return SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Text(
                                        "选择操作",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Wrap(
                                        runSpacing: 20,
                                        spacing: 20,
                                        children: [
                                          _buildRenameWidget(
                                              context, favorite, getData),
                                          _buildUnCollectWidget(
                                              context, favorite, getData),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 16,
                                      ),
                                      OutlinedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          "取消",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  // padding: EdgeInsets.zero,
                  child: const Icon(
                    CupertinoIcons.right_chevron,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: MediaQuery.sizeOf(context).width * 0.7,
      height: MediaQuery.sizeOf(context).height,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: favoriteLoading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Container(
              height: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor,
              width: MediaQuery.sizeOf(context).width * 0.7,
              child: favorites.value.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: MediaQuery.of(context).padding.top),
                      itemBuilder: (context, i) {
                        return buildFavoriteItem(favorites.value[i]);
                      },
                      itemCount: favorites.value.length,
                    )
                  : Center(
                      child: Text(
                        "暂无收藏",
                        style: TextStyle(
                            color: AppTheme.of(context).placeholderColor),
                      ),
                    ),
            ),
    );
  }

  SizedBox _buildUnCollectWidget(
      BuildContext context, favorite, Future<Null> Function() getData) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 100) / 4,
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              UiUtil.vibrate(FeedbackType.warning);
              showCupertinoModalPopup(
                context: context,
                builder: (context) {
                  return _buildUnCollectConfirmWidget(
                      context, favorite, getData);
                },
              );
            },
            child: Column(
              children: [
                Image.asset(
                  "assets/icons/collect.png",
                  width: 30,
                ),
                const Text(
                  "取消收藏",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SizedBox _buildUnCollectConfirmWidget(
      BuildContext context, favorite, Future<Null> Function() getData) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(), borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "取消收藏",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  "确定取消收藏？",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                ),
                const SizedBox(
                  height: 22,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            await dsmFileStationFavoriteDeleteForPage(
                                favorite['path']);
                            UiUtil.vibrate(FeedbackType.light);
                            UiUtil.toast("取消收藏成功");
                            getData();
                          } catch (e) {
                            UiUtil.toast("取消收藏失败");
                          }
                        },
                        child: const Text(
                          "取消收藏",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "取消",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SizedBox _buildRenameWidget(
      BuildContext context, favorite, Future<Null> Function() getData) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 100) / 4,
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              Log.debug(favorite['path']);
              Navigator.of(context).pop();
              showCupertinoDialog(
                context: context,
                builder: (context) => NameInputDialog(
                  title: "重命名",
                  onConfirm: (name) async {
                    try {
                      await dsmControlPanelGet({
                        "api": '"SYNO.FileStation.Favorite"',
                        "method": '"edit"',
                        "version": 2,
                        "path": favorite['path'],
                        "name": name,
                        "index": -1,
                      });
                      UiUtil.toast("重命名成功");
                      getData();
                    } catch (e) {
                      final raw = e is DSMException ? e.rawError : null;
                      final errors = raw?['errors'] as List?;
                      if (errors != null &&
                          errors.isNotEmpty &&
                          errors[0]['code'] == 414) {
                        UiUtil.toast("重命名失败：指定的名称已存在");
                      } else {
                        UiUtil.toast("重命名失败");
                      }
                    }
                  },
                ),
              );
            },
            child: Column(
              children: [
                Image.asset(
                  "assets/icons/edit.png",
                  width: 30,
                ),
                const Text(
                  "重命名",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
