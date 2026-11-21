import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/pages/setting/media_library_setting.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/ui_util.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 媒体库：按设置的库目录列出视频，海报墙形式，点开进播放页。
class MediaLibrary extends HookWidget {
  const MediaLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final items = useSignal<List<MediaItem>>([]);
    final loading = useSignal(false);
    final hasRoots = useSignal<bool?>(null); // null = 还没读设置

    Future<void> openPlayer(MediaItem item) async {
      await Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
        return VideoPlayerPage(
          url: fbDownloadUrl(
            baseUri: connectionStore.baseUri.value,
            path: item.path,
            sid: connectionStore.sid.value,
            mode: 'open',
          ),
          name: item.name,
          cover: item.coverPath,
          nfo: item.nfoPath,
          subtitles: item.subtitles,
        );
      }));
    }

    Future<void> reload() async {
      final roots = await loadMediaLibraryPaths();
      hasRoots.value = roots.isNotEmpty;
      if (roots.isEmpty) {
        items.value = [];
        return;
      }
      loading.value = true;
      try {
        final list = await scanMediaLibrary(roots);
        items.value = list;
        loading.value = false;
        // NFO 逐条补，补一条刷一条，先让海报墙出来
        for (final item in list) {
          final filled = await fillMediaNfo(item);
          if (identical(filled, item)) continue;
          items.value = [
            for (final e in items.value) e.path == filled.path ? filled : e
          ];
        }
      } catch (e) {
        Log.error("扫媒体库失败: $e");
        UiUtil.toast("扫媒体库失败：$e");
        loading.value = false;
      }
    }

    useEffect(() {
      reload();
      return null;
    }, const []);

    Future<void> openSetting() async {
      await Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => const MediaLibrarySetting()));
      reload();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('多媒体'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: reload,
          ),
          IconButton(
            tooltip: '库目录',
            icon: const Icon(Icons.folder_open),
            onPressed: openSetting,
          ),
        ],
      ),
      body: hasRoots.value == false
          ? _centerHint('还没有设置媒体库目录', '添加后这里会列出视频（最多往下 3 层）', openSetting)
          : items.value.isEmpty
              ? (loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _centerHint('库里没找到视频', '检查一下库目录，或点右上角刷新', reload))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: items.value.length,
                  itemBuilder: (context, i) =>
                      _Poster(item: items.value[i], onTap: openPlayer),
                ),
    );
  }

  Widget _centerHint(String title, String hint, VoidCallback onTap) => Center(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(hint,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

class _Poster extends StatelessWidget {
  final MediaItem item;
  final void Function(MediaItem) onTap;

  const _Poster({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cover = item.coverPath;
    return InkWell(
      onTap: () => onTap(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: cover.isNotBlank
                  ? ExtendedImage.network(
                      cover.startsWith("http")
                          ? cover
                          : thumbUrl(
                              baseUri: connectionStore.baseUri.value,
                              path: cover,
                              sid: connectionStore.sid.value,
                            ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      cacheWidth: 600,
                    )
                  : Container(
                      width: double.infinity,
                      color: Colors.grey.withValues(alpha: 0.2),
                      child: const Icon(Icons.movie, size: 40),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (item.subtitleLine.isNotBlank)
            Text(
              item.subtitleLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
