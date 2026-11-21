import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 在 NAS 上挑目录或文件，返回选中的 path 列表；放弃选择时返回 null。
///
/// [fileExtensions] 为空时只能选目录（右上角「选这个目录」），否则目录照常进，
/// 额外列出这些扩展名的文件供点选。
/// [multiSelect] 为 true 时每个条目可以勾选，右上角一次性确认多个。
class NasPathPicker extends HookWidget {
  final List<String> fileExtensions;
  final bool multiSelect;

  /// 起始目录，默认从根开始。
  final String initialPath;

  const NasPathPicker({
    super.key,
    this.fileExtensions = const [],
    this.multiSelect = false,
    this.initialPath = '/',
  });

  @override
  Widget build(BuildContext context) {
    final path = useSignal(initialPath);
    final items = useSignal<List<Map>>([]);
    final loading = useSignal(false);
    final selected = useSignal<List<String>>([]);
    final onlyDirs = fileExtensions.isEmpty;

    Future<void> load(String target) async {
      loading.value = true;
      try {
        final data = target == '/'
            ? await dsmFileStationListShareForPage()
            : await dsmFileStationListForPage(target);
        final raw = (data['files'] ?? data['shares']) as List? ?? const [];
        final list = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) =>
                e['isdir'] == true ||
                fileExtensions
                    .contains('${e['name']}'.split('.').last.toLowerCase()))
            .toList()
          // 目录排前面
          ..sort((a, b) => (b['isdir'] == true ? 1 : 0)
              .compareTo(a['isdir'] == true ? 1 : 0));
        items.value = list;
      } catch (e) {
        Log.error("读取 NAS 目录失败: $e");
        UiUtil.toast("读取目录失败");
        items.value = [];
      } finally {
        loading.value = false;
      }
    }

    void go(String target) {
      path.value = target;
      load(target);
    }

    void toggle(String target) {
      selected.value = selected.value.contains(target)
          ? (selected.value.where((e) => e != target).toList())
          : [...selected.value, target];
    }

    void pop(List<String> paths) => Navigator.of(context).pop(paths);

    useEffect(() {
      load(initialPath);
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: path.value == '/'
            ? AppBackButton(context)
            : IconButton(
                tooltip: '上一级',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final parent =
                      path.value.substring(0, path.value.lastIndexOf('/'));
                  go(parent.isEmpty ? '/' : parent);
                },
              ),
        title: Text(path.value == '/'
            ? (onlyDirs ? '选择 NAS 目录' : '选择 NAS 上的文件')
            : path.value.split('/').last),
        actions: [
          if (onlyDirs)
            TextButton(
              onPressed: path.value == '/' ? null : () => pop([path.value]),
              child: const Text('选这个目录'),
            ),
          if (multiSelect)
            TextButton(
              onPressed:
                  selected.value.isEmpty ? null : () => pop(selected.value),
              child: Text(
                  '确定${selected.value.isEmpty ? "" : "(${selected.value.length})"}'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (multiSelect && selected.value.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              child: Text(
                '已选：${selected.value.join("、")}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: loading.value
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: items.value.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = items.value[i];
                      final isDir = e['isdir'] == true;
                      final p = '${e['path']}';
                      return ListTile(
                        leading: Icon(
                          isDir ? Icons.folder : Icons.insert_drive_file,
                          color: isDir
                              ? null
                              : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text("${e['name']}",
                            overflow: TextOverflow.ellipsis),
                        trailing: multiSelect
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDir)
                                    IconButton(
                                      tooltip: '进入',
                                      icon: const Icon(Icons.arrow_forward_ios,
                                          size: 14),
                                      onPressed: () => go(p),
                                    ),
                                  Checkbox(
                                    value: selected.value.contains(p),
                                    onChanged: (_) => toggle(p),
                                  ),
                                ],
                              )
                            : null,
                        // 多选时点一行就是勾选，进目录用右侧箭头
                        onTap: () {
                          if (multiSelect) {
                            toggle(p);
                          } else if (isDir) {
                            go(p);
                          } else {
                            pop([p]);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
