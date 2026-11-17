import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class AddTracker extends HookWidget {
  final String id;
  const AddTracker(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    // Never read during build, so writing it does not rebuild the page
    // (same behaviour as the old plain field).
    final tracker = useSignal("");
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
                onChanged: (v) => tracker.value = v,
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
              List<String> temp = tracker.value.split("\n");
              List<String> trackers = [];
              for (var item in temp) {
                if (item.trim() != "") {
                  trackers.add(item.trim());
                }
              }
              if (tracker.value.isEmpty) {
                UiUtil.toast("请填写Tacker");
                return;
              }
              try {
                await dsmDownloadStation2TaskBTTrackerAdd(
                    taskId: id, tracker: trackers);
                UiUtil.toast("添加Tracker成功");
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }
              } catch (e) {
                final code = e is DSMException ? e.code : -1;
                UiUtil.toast("添加Tracker失败，代码$code");
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
