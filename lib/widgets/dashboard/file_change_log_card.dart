
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:garden/widgets/dashboard/dashboard_card_parts.dart';

class DashboardFileChangeLogCard extends HookWidget {
  const DashboardFileChangeLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    final fileChangeLogs = useListSignal([]);
    final error = useSignal('');

    fetchData() {
      dsmCoreSyslogClientLogList()
          .then((res) => {fileChangeLogs.value = res['items']})
          .catchError((e) {
        error.value = e.toString();
        return <dynamic>{};
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/file_change.png",
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "文件更改日志",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const DashboardCardItemCollapse("FileChangeLog")
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Builder(builder: (context) {
              if (fileChangeLogs.watch(context).isEmpty) {
                return Text(error.isNotEmpty ? error.value : '暂无文件更新日志');
              }
              if (context.isCardItemCollapsed('FileChangeLog')) {
                return SizedBox(
                  height: 300,
                  child: CupertinoScrollbar(
                    child: ListView.builder(
                      itemBuilder: (context, i) {
                        return _DashboardFileChangeLogItem(fileChangeLogs[i]);
                      },
                      itemCount: fileChangeLogs.length,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardFileChangeLogItem extends StatelessWidget {
  const _DashboardFileChangeLogItem(this.log);
  final ReadonlySignal<Map> log;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Watch((context) {
              final cmd = log.select((v) => v['cmd']);
              return Icon(cmd.value == "delete"
                  ? Icons.delete
                  : cmd.value == "copy"
                      ? Icons.copy
                      : cmd.value == "edit"
                          ? Icons.edit
                          : cmd.value == "move"
                              ? Icons.drive_file_move_outline
                              : cmd.value == "download"
                                  ? Icons.download_outlined
                                  : cmd.value == "upload"
                                      ? Icons.upload_outlined
                                      : cmd.value == "rename"
                                          ? Icons.drive_file_rename_outline
                                          : Icons.code);
            }),
            Expanded(
              child: Text(
                "${log.watch(context)['descr']}",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

