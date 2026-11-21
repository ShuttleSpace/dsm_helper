import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';

/// 播放历史 + 统计：数据来自播放时记下的 `play_history`，不额外埋点。
class PlayHistoryPage extends HookWidget {
  const PlayHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final records = useState<List<PlayRecord>>(const []);
    final loading = useState(true);

    Future<void> reload() async {
      records.value = await loadPlayHistory();
      loading.value = false;
    }

    useEffect(() {
      reload();
      return null;
    }, const []);

    final finished = records.value.where((e) => e.finished).length;
    final totalDuration =
        records.value.fold(Duration.zero, (sum, e) => sum + e.duration);
    final recently = records.value
        .where((e) => DateTime.now().difference(e.watchedAt).inDays < 7)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放历史'),
        leading: AppBackButton(context),
        actions: [
          if (records.value.isNotEmpty)
            IconButton(
              tooltip: '清空历史',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                await clearPlayHistory();
                await reload();
                UiUtil.toast('已清空播放历史');
              },
            ),
        ],
      ),
      body: loading.value
          ? const Center(child: CircularProgressIndicator())
          : records.value.isEmpty
              ? const Center(
                  child: Text('还没有播放记录', style: TextStyle(color: Colors.grey)),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        _stat('看过', '${records.value.length} 部'),
                        _stat('看完', '$finished 部'),
                        _stat('总片长', formatPlayDuration(totalDuration)),
                        _stat('近 7 天', '$recently 部'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final record in records.value)
                      _HistoryTile(
                        record: record,
                        onTap: () async {
                          await Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => VideoPlayerPage(
                                url: fbDownloadUrl(
                                  baseUri: connectionStore.baseUri.value,
                                  path: record.path,
                                  sid: connectionStore.sid.value,
                                  mode: 'open',
                                ),
                                name: record.name,
                                mediaPath: record.path,
                                playlist: [
                                  for (final e in records.value)
                                    MediaItem(name: e.name, path: e.path),
                                ],
                              ),
                            ),
                          );
                          await reload();
                        },
                        onDelete: () async {
                          await removePlayHistory(record.path);
                          await reload();
                        },
                      ),
                  ],
                ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
}

class _HistoryTile extends StatelessWidget {
  final PlayRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile(
      {required this.record, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: record.progress,
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.finished
                          ? '已看完 · ${formatPlayDuration(record.duration)}'
                          : '剩 ${formatPlayDuration(record.remaining)} · 共 ${formatPlayDuration(record.duration)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '删除这条',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「1 小时 20 分钟」这种粗粒度，统计和历史都用它。
String formatPlayDuration(Duration duration) {
  if (duration.inMinutes < 1) return '${duration.inSeconds} 秒';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes 分钟';
  return minutes == 0 ? '$hours 小时' : '$hours 小时 $minutes 分钟';
}
