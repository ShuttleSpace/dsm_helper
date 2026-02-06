import 'package:garden/util/http_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Reward extends StatefulWidget {
  const Reward({super.key});

  @override
  RewardState createState() => RewardState();
}

class RewardState extends State<Reward> {
  bool loading = true;
  List rewards = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await DsmApi.reward();
    if (res['code'] == 1) {
      setState(() {
        loading = false;
        rewards = res['data'];
      });
    } else {
      UiUtil.toast("获取列表失败");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildRewardItem(reward) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("打赏名单"),
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, i) {
                return _buildRewardItem(rewards[i]);
              },
              itemCount: rewards.length,
              separatorBuilder: (context, i) {
                return const SizedBox(
                  height: 20,
                );
              },
            ),
    );
  }
}
