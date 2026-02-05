import 'package:garden/util/http_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class AddTracker extends StatefulWidget {
  final String id;
  const AddTracker(this.id, {super.key});
  @override
  AddTrackerState createState() => AddTrackerState();
}

class AddTrackerState extends State<AddTracker> {
  String tracker = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: TextField(
                onChanged: (v) => tracker = v,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Tracker链接，每行一个',
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton(
            onPressed: () async {
              List<String> temp = tracker.split("\n");
              List<String> trackers = [];
              for (var item in temp) {
                if (item.trim() != "") {
                  trackers.add(item.trim());
                }
              }
              if (tracker.isEmpty) {
                UiUtil.toast("请填写Tacker");
                return;
              }
              var res = await Api.downloadTrackerAdd(widget.id, trackers);
              if (res['success']) {
                UiUtil.toast("添加Tracker成功");
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }
              } else {
                UiUtil.toast("添加Tracker失败，代码${res['error']['code']}");
              }
            },
            child: const Text(
              ' 创建 ',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
