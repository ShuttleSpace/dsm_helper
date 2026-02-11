import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class TaskRecord extends StatefulWidget {
  final int id;
  const TaskRecord(this.id, {super.key});
  @override
  TaskRecordState createState() => TaskRecordState();
}

class TaskRecordState extends State<TaskRecord> {
  List records = [];
  bool loading = true;
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await dsmCoreTaskSchedulerResultGet(widget.id);
    if (res['success']) {
      setState(() {
        loading = false;
        records = res['data'];
      });
    } else {
      UiUtil.toast("加载失败");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildRecordItem(record) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("查看结果"),
      ),
      body: loading
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
                return _buildRecordItem(records[i]);
              },
              itemCount: records.length,
            ),
    );
  }
}
