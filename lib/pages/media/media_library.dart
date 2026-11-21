import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/pages/media/media_setting.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/tmdb_util.dart';
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
    final query = useSignal('');
    final sort = useSignal(MediaSort.name);
    final searching = useState(false);
    final watching = useSignal<Map<String, dynamic>>({});
    final depth = useSignal(mediaScanDepth);
    final viewMode = useSignal(MediaViewMode.poster);

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
          mediaPath: item.path,
        );
      }));
      // 回来时续播位置可能变了
      watching.value = await loadContinueWatching();
    }

    Future<void> reload() async {
      final roots = await loadMediaLibraryPaths();
      depth.value = await loadMediaScanDepth();
      viewMode.value = await loadMediaViewMode();
      final useTmdbPoster = await loadMediaUseTmdbPoster();
      hasRoots.value = roots.isNotEmpty;
      watching.value = await loadContinueWatching();
      if (roots.isEmpty) {
        items.value = [];
        return;
      }
      loading.value = true;
      try {
        final list = await scanMediaLibrary(roots, maxDepth: depth.value);
        items.value = list;
        loading.value = false;
        // NFO 逐条补，补一条刷一条，先让海报墙出来
        final apiKey = await StorageUtil.getString(tmdbApiKeyStorageKey) ?? '';
        for (final item in list) {
          var filled = await fillMediaNfo(item);
          // 没本地封面时用 TMDB 的海报（走 tmdb 缓存），没 key 就跳过
          if (filled.coverPath.isBlank && useTmdbPoster && apiKey.isNotBlank) {
            final info = await fetchTmdbInfo(apiKey, item.name);
            if (info != null && info.poster.isNotBlank) {
              filled = filled.withCover(info.poster);
            }
          }
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
      await Navigator.of(context)
          .push(CupertinoPageRoute(builder: (_) => const MediaSetting()));
      await reload();
    }

    final shown = filterAndSortMediaItems(items.value, query.value, sort.value);
    // 继续观看：库里有、且看过一半以内的
    final byPath = {for (final e in items.value) e.path: e};
    final resumed = [
      for (final entry in watching.value.entries)
        if (byPath[entry.key] != null &&
            entry.value is Map &&
            ((entry.value as Map)['pos'] as num? ?? 0) > 0)
          (byPath[entry.key]!, entry.value as Map)
    ];

    return Scaffold(
      appBar: AppBar(
        title: searching.value
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: '搜片名', border: InputBorder.none),
                onChanged: (v) => query.value = v,
              )
            : const Text('多媒体'),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: Icon(searching.value ? Icons.close : Icons.search),
            onPressed: () {
              searching.value = !searching.value;
              if (!searching.value) query.value = '';
            },
          ),
          IconButton(
            tooltip: viewMode.value == MediaViewMode.poster ? '按文件夹看' : '按海报看',
            icon: Icon(viewMode.value == MediaViewMode.poster
                ? Icons.folder_outlined
                : Icons.grid_view),
            onPressed: () {
              viewMode.value = viewMode.value == MediaViewMode.poster
                  ? MediaViewMode.folder
                  : MediaViewMode.poster;
              saveMediaViewMode(viewMode.value);
            },
          ),
          PopupMenuButton<MediaSort>(
            tooltip: '排序',
            icon: const Icon(Icons.sort),
            initialValue: sort.value,
            onSelected: (value) => sort.value = value,
            itemBuilder: (context) => const [
              PopupMenuItem(value: MediaSort.name, child: Text('按片名')),
              PopupMenuItem(value: MediaSort.year, child: Text('按年份')),
              PopupMenuItem(value: MediaSort.rating, child: Text('按评分')),
            ],
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: reload,
          ),
          IconButton(
            tooltip: '多媒体设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: openSetting,
          ),
        ],
      ),
      body: hasRoots.value == false
          ? _centerHint(
              '还没有设置媒体库目录', '添加后这里会列出视频（最多往下 ${depth.value} 层）', openSetting)
          : shown.isEmpty && resumed.isEmpty
              ? (loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _centerHint(
                      query.value.isBlank ? '库里没找到视频' : '没搜到「${query.value}」',
                      '检查一下库目录，或点右上角刷新',
                      reload))
              : Column(
                  children: [
                    if (resumed.isNotEmpty && query.value.isBlank)
                      SizedBox(
                        height: 132,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: resumed.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) => _ResumeCard(
                            item: resumed[i].$1,
                            pos: (resumed[i].$2['pos'] as num).toInt(),
                            dur: (resumed[i].$2['dur'] as num? ?? 0).toInt(),
                            onTap: () => openPlayer(resumed[i].$1),
                          ),
                        ),
                      ),
                    Expanded(
                      child: viewMode.value == MediaViewMode.poster
                          ? _grid(shown, openPlayer)
                          : _folderList(shown, openPlayer),
                    ),
                  ],
                ),
    );
  }

  /// 一个可滚的网格；文件夹分组时嵌在 ListView 里，所以 shrinkWrap。
  Widget _grid(List<MediaItem> list, void Function(MediaItem) onTap,
          {bool shrink = false}) =>
      GridView.builder(
        padding: shrink ? EdgeInsets.zero : const EdgeInsets.all(12),
        shrinkWrap: shrink,
        physics: shrink ? const NeverScrollableScrollPhysics() : null,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) => _Poster(item: list[i], onTap: onTap),
      );

  /// 按所在 NAS 目录分段。shortcut: 每段整段构建，几千部片会卡，真要上量再换 CustomScrollView。
  Widget _folderList(List<MediaItem> list, void Function(MediaItem) onTap) {
    final groups = groupByFolder(list);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.key,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                Text("${entry.value.length}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          _grid(entry.value, onTap, shrink: true),
        ],
      ],
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

/// 封面地址：本地封面走缩略图接口，TMDB 海报已经是完整 URL。
Widget mediaCover(String cover, {double? height}) {
  if (cover.isBlank) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.withValues(alpha: 0.2),
      child: const Icon(Icons.movie, size: 40),
    );
  }
  return ExtendedImage.network(
    cover.startsWith("http")
        ? cover
        : thumbUrl(
            baseUri: connectionStore.baseUri.value,
            path: cover,
            sid: connectionStore.sid.value,
          ),
    fit: BoxFit.cover,
    width: double.infinity,
    height: height,
    cacheWidth: 600,
  );
}

class _Poster extends StatelessWidget {
  final MediaItem item;
  final void Function(MediaItem) onTap;

  const _Poster({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: mediaCover(item.coverPath),
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

/// 「继续观看」里的一张小卡：封面 + 进度条 + 剩余时间。
class _ResumeCard extends StatelessWidget {
  final MediaItem item;
  final int pos;
  final int dur;
  final VoidCallback onTap;

  const _ResumeCard({
    required this.item,
    required this.pos,
    required this.dur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = dur <= 0 ? 0.0 : (pos / dur).clamp(0.0, 1.0);
    final left = dur - pos;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    mediaCover(item.coverPath),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 3,
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(item.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            Text('剩 ${(left / 60).ceil()} 分钟',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
