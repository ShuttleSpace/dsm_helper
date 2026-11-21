import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 在 NAS 上挑一个字幕文件，返回它的 path；放弃选择时返回 null。
class SubtitlePicker extends HookWidget {
  const SubtitlePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final path = useSignal('/');
    final items = useSignal<List<Map>>([]);
    final loading = useSignal(false);

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
                FileTypeUtil.subtitleExtensions
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

    useEffect(() {
      load('/');
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
        title: Text(
            path.value == '/' ? '选择 NAS 上的字幕' : path.value.split('/').last),
      ),
      body: loading.value
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: items.value.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = items.value[i];
                final isDir = e['isdir'] == true;
                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.subtitles,
                    color: isDir ? null : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text("${e['name']}", overflow: TextOverflow.ellipsis),
                  onTap: () {
                    if (isDir) {
                      go('${e['path']}');
                    } else {
                      Navigator.of(context).pop('${e['path']}');
                    }
                  },
                );
              },
            ),
    );
  }
}
