import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class TaskRecord extends HookWidget {
  final int id;
  const TaskRecord(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final records = useSignal<List>([]);
    final loading = useSignal(true);

    getData() async {
      try {
        final data = await dsmCoreTaskRecordForPage(id);
        records.value = data['records'] is List
            ? List<dynamic>.from(data['records'] as List)
            : [];
      } catch (e) {
        UiUtil.toast("加载失败");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      } finally {
        loading.value = false;
      }
    }

    Widget buildRecordItem(record) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin:
          const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${record['start_time']} 至 ${record['stop_time']}",
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    "脚本：",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${record['script_in'].trim()}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      if (record['exit_type'] == 'normal')
                        const Label("正常", Colors.green)
                      else
                        Label("中断(${record['exit_code']})", Colors.red),
                      const SizedBox(
                        width: 5,
                      ),
                      const Text(
                        "标准输出/结果：",
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${record['script_out'].trim()}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("查看结果"),
      ),
      body: loading.value
          ? Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: .7),
              child: const Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, i) {
                return buildRecordItem(records.value[i]);
              },
              itemCount: records.value.length,
            ),
    );
  }
}
