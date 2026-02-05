import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class Favorite extends StatefulWidget {
  final Function callback;
  const Favorite(this.callback, {super.key});
  @override
  FavoriteState createState() => FavoriteState();
}

class FavoriteState extends State<Favorite> {
  bool favoriteLoading = true;
  List favorites = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    setState(() {
      favoriteLoading = true;
    });
    var res = await Api.favoriteList();
    setState(() {
      favoriteLoading = false;
    });
    if (res['success']) {
      setState(() {
        favorites = res['data']['favorites'];
      });
    }
  }

  Widget _buildFavoriteItem(favorite) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: OutlinedButton(
        onPressed: () {
          if (favorite['status'] == "broken") {
            UiUtil.toast("文件或目录不存在");
          } else {
            Navigator.of(context).pop(favorite['path']);
            widget.callback(favorite['path']);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      return Material(
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
                                      SizedBox(
                                        width:
                                            (MediaQuery.sizeOf(context).width -
                                                    100) /
                                                4,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            debugPrint(favorite['path']);
                                            TextEditingController
                                                nameController =
                                                TextEditingController.fromValue(
                                                    TextEditingValue(
                                                        text:
                                                            favorite['name']));
                                            Navigator.of(context).pop();
                                            String name = "";
                                            showCupertinoDialog(
                                              context: context,
                                              builder: (context) {
                                                return Material(
                                                  color: Colors.transparent,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Card(
                                                        shape: RoundedRectangleBorder(
                                                            side:
                                                                const BorderSide(),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5)),
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 50),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(20),
                                                          child: Column(
                                                            children: [
                                                              const Text(
                                                                "重命名",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              const SizedBox(
                                                                height: 16,
                                                              ),
                                                              Card(
                                                                shape: RoundedRectangleBorder(
                                                                    side:
                                                                        const BorderSide(),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            5)),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child:
                                                                      TextField(
                                                                    onChanged:
                                                                        (v) =>
                                                                            name =
                                                                                v,
                                                                    controller:
                                                                        nameController,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      border: InputBorder
                                                                          .none,
                                                                      hintText:
                                                                          "请输入新的名称",
                                                                      labelText:
                                                                          "文件名",
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 16,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        OutlinedButton(
                                                                      onPressed:
                                                                          () async {
                                                                        if (name.trim() ==
                                                                            "") {
                                                                          HttpUtil
                                                                              .instance
                                                                              .toast("请输入新文件名");
                                                                          return;
                                                                        }
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        var res = await Api.favoriteRename(
                                                                            favorite['path'],
                                                                            name);
                                                                        if (res[
                                                                            'success']) {
                                                                          HttpUtil
                                                                              .instance
                                                                              .toast("重命名成功");
                                                                          getData();
                                                                        } else {
                                                                          if (res['error']['errors'] != null &&
                                                                              res['error']['errors'].length > 0 &&
                                                                              res['error']['errors'][0]['code'] == 414) {
                                                                            UiUtil.toast("重命名失败：指定的名称已存在");
                                                                          } else {
                                                                            UiUtil.toast("重命名失败");
                                                                          }
                                                                        }
                                                                      },
                                                                      child:
                                                                          const Text(
                                                                        "确定",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                18),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 16,
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        OutlinedButton(
                                                                      onPressed:
                                                                          () async {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      child:
                                                                          const Text(
                                                                        "取消",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                18),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
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
                                      SizedBox(
                                        width:
                                            (MediaQuery.sizeOf(context).width -
                                                    100) /
                                                4,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            HttpUtil.instance
                                                .vibrate(FeedbackType.warning);
                                            showCupertinoModalPopup(
                                              context: context,
                                              builder: (context) {
                                                return Material(
                                                  color: Colors.transparent,
                                                  child: Card(
                                                    shape: RoundedRectangleBorder(
                                                        side:
                                                            const BorderSide(),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5)),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          const Text(
                                                            "取消收藏",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          const Text(
                                                            "确定取消收藏？",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                          ),
                                                          const SizedBox(
                                                            height: 22,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    OutlinedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    var res = await Api
                                                                        .favoriteDelete(
                                                                            favorite['path']);
                                                                    if (res[
                                                                        'success']) {
                                                                      HttpUtil
                                                                          .instance
                                                                          .vibrate(
                                                                              FeedbackType.light);
                                                                      HttpUtil
                                                                          .instance
                                                                          .toast(
                                                                              "取消收藏成功");
                                                                      getData();
                                                                    }
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                    "取消收藏",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        color: Colors
                                                                            .redAccent),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 20,
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    OutlinedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                    "取消",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18),
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
                                                );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.7,
      height: MediaQuery.sizeOf(context).height,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: favoriteLoading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Container(
              height: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor,
              width: MediaQuery.sizeOf(context).width * 0.7,
              child: favorites.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: MediaQuery.of(context).padding.top),
                      itemBuilder: (context, i) {
                        return _buildFavoriteItem(favorites[i]);
                      },
                      itemCount: favorites.length,
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
}
