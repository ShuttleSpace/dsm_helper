import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/pages/common/nas_path_picker.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 媒体库目录管理：加/删要扫的 NAS 目录，多媒体页按这些目录建库。
class MediaLibrarySetting extends HookWidget {
  const MediaLibrarySetting({super.key});

  @override
  Widget build(BuildContext context) {
    final paths = useSignal<List<String>>([]);

    useEffect(() {
      loadMediaLibraryPaths().then((value) => paths.value = value);
      return null;
    }, const []);

    Future<void> add() async {
      final path = await Navigator.of(context).push<String>(
        CupertinoPageRoute(builder: (_) => const NasPathPicker()),
      );
      if (path == null || paths.value.contains(path)) return;
      paths.value = [...paths.value, path];
      await saveMediaLibraryPaths(paths.value);
    }

    Future<void> remove(String path) async {
      paths.value = paths.value.where((e) => e != path).toList();
      await saveMediaLibraryPaths(paths.value);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体库目录'),
        leading: AppBackButton(context),
        actions: [
          IconButton(
            tooltip: '添加目录',
            icon: const Icon(Icons.add),
            onPressed: add,
          ),
        ],
      ),
      body: paths.value.isEmpty
          ? const Center(
              child: Text(
                '还没有目录，点右上角 + 选一个 NAS 目录',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          : ListView.separated(
              itemCount: paths.value.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final path = paths.value[i];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(path, overflow: TextOverflow.ellipsis),
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
