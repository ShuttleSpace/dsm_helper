import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Reward extends HookWidget {
  const Reward({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final rewards = useSignal<List>([]);

    getData() async {
      try {
        final res = await dsmReward();
        if (res is Map && res['code'] == 1) {
          rewards.value = res['data'] ?? [];
        } else {
          throw StateError('reward list failed');
        }
      } catch (e) {
        UiUtil.toast("获取列表失败");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      } finally {
        loading.value = false;
      }
    }

    Widget buildRewardItem(reward) {
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(child: Text(reward['name'])),
            if (reward['amount'] != null) Text("￥${reward['amount']}"),
          ],
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
        title: const Text("打赏名单"),
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, i) {
                return buildRewardItem(rewards.value[i]);
              },
              itemCount: rewards.value.length,
              separatorBuilder: (context, i) {
                return const SizedBox(
                  height: 20,
                );
              },
            ),
    );
  }
}
