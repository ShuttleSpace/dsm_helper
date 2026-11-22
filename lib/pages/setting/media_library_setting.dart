import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/music_library.dart';
import 'package:garden/widgets/folder_picker_sheet.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 媒体库目录管理：加/改/删/清空要扫的 NAS 目录，多媒体页按这些目录建库。
/// 选目录复用上传时那个 `SelectFolder`（`showFolderPickerSheet`），多选一次性加多个。
class MediaLibrarySetting extends HookWidget {
  /// [music] 为 true 时管的是音乐目录（单独一组），否则是视频库目录。
  final bool music;
  const MediaLibrarySetting({super.key, this.music = false});

  @override
  Widget build(BuildContext context) {
    final paths = useSignal<List<String>>([]);
    Future<List<String>> load() =>
        music ? loadMusicLibraryPaths() : loadMediaLibraryPaths();
    Future<void> save(List<String> value) =>
        music ? saveMusicLibraryPaths(value) : saveMediaLibraryPaths(value);

    useEffect(() {
      load().then((value) => paths.value = value);
      return null;
    }, const []);

    Future<List<String>?> pick({bool multi = false}) async {
      final res = await showFolderPickerSheet(context, multi: multi);
      if (res is! List || res.isEmpty) return null;
      return res.map((e) => '$e').toList();
    }

    /// 多选目录，已有的自动去重。
    Future<void> add() async {
      final picked = await pick(multi: true);
      if (picked == null) return;
      paths.value = {
        ...paths.value,
        ...picked.where((e) => e != '/'),
      }.toList();
      await save(paths.value);
    }

    /// 点一条 = 换成别的目录。
    Future<void> edit(String oldPath) async {
      final picked = await pick();
      if (picked == null) return;
      final next = picked.first;
      if (next == '/' || (next != oldPath && paths.value.contains(next))) {
        return;
      }
      paths.value = [
        for (final e in paths.value) e == oldPath ? next : e,
      ];
      await save(paths.value);
    }

    Future<void> remove(String path) async {
      paths.value = paths.value.where((e) => e != path).toList();
      await save(paths.value);
    }

    Future<void> clear() async {
      paths.value = [];
      await save(paths.value);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(music ? '音乐目录' : '媒体库目录'),
        leading: AppBackButton(context),
        actions: [
          IconButton(
            tooltip: '添加目录（可多选）',
            icon: const Icon(Icons.add),
            onPressed: add,
          ),
          if (paths.value.isNotEmpty)
            IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: clear,
            ),
        ],
      ),
      body: paths.value.isEmpty
          ? const Center(
              child: Text(
                '还没有目录，点右上角 + 选 NAS 上的目录（可多选）',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          : ListView.separated(
              itemCount: paths.value.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      '共 ${paths.value.length} 个目录，点一条可以改，右侧 × 删除',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }
                final path = paths.value[i - 1];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(path, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    path.split('/').where((e) => e.isNotEmpty).last,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () => edit(path),
                  trailing: IconButton(
                    tooltip: '移除',
                    icon: const Icon(Icons.close),
                    onPressed: () => remove(path),
                  ),
                );
              },
            ),
    );
  }
}
