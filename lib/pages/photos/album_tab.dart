import 'dart:async';

import 'package:garden/api/dsm_api.dart';

import 'package:garden/models/photos/album_model.dart';
import 'package:garden/models/photos/general_tag_model.dart';
import 'package:garden/models/photos/geocoding_model.dart';
import 'package:garden/models/photos/photo_model.dart';
import 'package:garden/pages/photos/album_page.dart';
import 'package:garden/pages/photos/general_tag_page.dart';
import 'package:garden/pages/photos/geocoding_page.dart';
import 'package:garden/pages/photos/timeline_page.dart';
import 'package:garden/pages/photos/widgets/thumbnail_card.dart';
import 'package:garden/util/list_cache.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bottom_action_sheet.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:signals_hooks/signals_hooks.dart';

String? validateAlbumName(String? raw) {
  final name = raw?.trim() ?? '';
  if (name.isEmpty) return '请输入相册名称';
  if (name.length > 60) return '相册名称不能超过 60 个字符';
  return null;
}

class AlbumTab extends HookWidget {
  const AlbumTab(this.isTeam, {super.key});
  final bool isTeam;

  @override
  Widget build(BuildContext context) {
    final albums = useSignal<List<AlbumModel>>([]);
    final recentlyAdds = useSignal<List<PhotoModel>>([]);
    final videos = useSignal<List<PhotoModel>>([]);
    final geocodings = useSignal<List<GeocodingModel>>([]);
    final generalTags = useSignal<List<GeneralTagModel>>([]);
    final albumWidth = MediaQuery.sizeOf(context).width / 5;

    getAlbum() async {
      final cacheKey = 'photos|albums|$isTeam';
      final cached = await ListCache.read(cacheKey) as List?;
      if (cached != null && cached.isNotEmpty) {
        albums.value = [for (final e in cached) AlbumModel.fromJson(e)];
      }
      // 刷新失败不得让调用方误判为写入失败，这里自行吞掉并记日志
      try {
        albums.value = await AlbumModel.fetch(
            additional: ["sharing_info", "thumbnail"],
            limit: 100,
            isTeam: isTeam);
        unawaited(
            ListCache.write(cacheKey, [for (final a in albums.value) a.toJson()]));
        Log.debug("相册：${albums.value.length}");
      } catch (e) {
        Log.error("相册加载失败: $e");
      }
    }

    getRecently() async {
      recentlyAdds.value = await PhotoModel.recentlyAdd(
          limit: 4, isTeam: isTeam, additional: ['thumbnail'], type: 'photo');
      Log.debug("最近添加：${recentlyAdds.value.length}");
    }

    getVideos() async {
      videos.value = await PhotoModel.fetch(
          limit: 4, isTeam: isTeam, additional: ['thumbnail'], type: 'video');
      Log.debug("视频：${videos.value.length}");
    }

    getGeocoding() async {
      geocodings.value = await GeocodingModel.fetch(
          limit: 4, isTeam: isTeam, additional: ['thumbnail']);
      Log.debug("位置：${geocodings.value.length}");
    }

    getGeneral() async {
      generalTags.value = await GeneralTagModel.fetch(
          limit: 4, isTeam: isTeam, additional: ['thumbnail']);
      Log.debug("标签：${generalTags.value.length}");
    }

    getData() {
      recentlyAdds.value = [];
      videos.value = [];
      geocodings.value = [];
      generalTags.value = [];
      getRecently();
      getVideos();
      getGeocoding();
      getGeneral();
    }

    useEffect(() {
      getAlbum();
      return null;
    }, const []);

    useEffect(() {
      getData();
      return null;
    }, [isTeam]);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          runSpacing: 20,
          spacing: 20,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (context) {
                  return GeocodingPage(isTeam);
                }));
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThumbnailCard(
                    geocodings.value
                        .takeWhile((t) =>
                            t.additional != null &&
                            t.additional!.thumbnail != null)
                        .map((e) => e.additional!.thumbnail!)
                        .toList(),
                    width: albumWidth,
                    isTeam: isTeam,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "位置",
                    style: TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (context) {
                  return GeneralTagPage(isTeam);
                }));
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThumbnailCard(
                    generalTags.value
                        .takeWhile((t) =>
                            t.additional != null &&
                            t.additional!.thumbnail != null)
                        .map((e) => e.additional!.thumbnail!)
                        .toList(),
                    width: albumWidth,
                    isTeam: isTeam,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "标签",
                    style: TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (context) {
                  return TimelinePage(title: "视频", type: 'video', isTeam: isTeam);
                }));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThumbnailCard(
                    videos.value
                        .takeWhile((t) =>
                            t.additional != null &&
                            t.additional!.thumbnail != null)
                        .map((e) => e.additional!.thumbnail!)
                        .toList(),
                    width: albumWidth,
                    isTeam: isTeam,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "视频",
                    style: TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (context) {
                  return TimelinePage(
                      title: "最近添加", isTeam: isTeam, recentlyAdd: true);
                }));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThumbnailCard(
                    recentlyAdds.value
                        .takeWhile((t) =>
                            t.additional != null &&
                            t.additional!.thumbnail != null)
                        .map((e) => e.additional!.thumbnail!)
                        .toList(),
                    width: albumWidth,
                    isTeam: isTeam,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "最近添加",
                    style: TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        if (!isTeam)
          GestureDetector(
            onTap: () => showCupertinoDialog(
              context: context,
              builder: (context) => _AlbumCreateDialog(onCreate: (name) async {
                try {
                  await dsmFotoBrowseAlbumCreate(name);
                  UiUtil.toast("已创建「$name」");
                  await getAlbum();
                } catch (_) {
                  UiUtil.toast("创建失败，请重试");
                }
              }),
            ),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(CupertinoIcons.add_circled, size: 20),
                  SizedBox(width: 8),
                  Text("新建相册", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ...albums.value.map((e) {
          deleteAlbum() {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => BottomActionSheet(
                title: "相册操作",
                actions: [
                  BottomActionItem(
                    label: "删除相册",
                    iconAsset: "assets/icons/delete.png",
                    labelColor: Colors.redAccent,
                    onPressed: () => showCupertinoModalPopup(
                      context: context,
                      builder: (context) => BottomConfirmSheet(
                        title: "确认删除",
                        content: "删除相册「${e.name ?? ''}」？",
                        confirmText: "确认删除",
                        showTrailingSpace: true,
                        onConfirm: () async {
                          try {
                            await dsmFotoBrowseAlbumDelete(e.id.toString());
                            UiUtil.toast("已删除「${e.name ?? ''}」");
                            await getAlbum();
                          } catch (_) {
                            UiUtil.toast("删除失败，请重试");
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return AlbumPage(
                  e,
                  isTeam: isTeam,
                );
              }));
            },
            onLongPress: isTeam ? null : deleteAlbum,
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
        }),
      ],
    );
  }
}

class _AlbumCreateDialog extends StatefulWidget {
  const _AlbumCreateDialog({required this.onCreate});
  final Future<void> Function(String name) onCreate;

  @override
  State<_AlbumCreateDialog> createState() => _AlbumCreateDialogState();
}

class _AlbumCreateDialogState extends State<_AlbumCreateDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void create() {
    final error = validateAlbumName(controller.text);
    if (error != null) {
      UiUtil.toast(error);
      return;
    }
    Navigator.of(context).pop();
    widget.onCreate(controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("新建相册"),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: controller,
          autofocus: true,
          placeholder: "相册名称",
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("取消"),
        ),
        CupertinoDialogAction(
          onPressed: create,
          child: const Text("创建"),
        ),
      ],
    );
  }
}
