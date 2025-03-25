import 'package:cool_ui/cool_ui.dart';
import 'package:garden/models/setting/vip_record_model.dart';
import 'package:garden/themes/app_theme.dart';
import 'package:garden/util/function.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VipRecord extends StatefulWidget {
  const VipRecord();

  @override
  State<VipRecord> createState() => _VipRecordState();
}

class _VipRecordState extends State<VipRecord> {
  List<VipRecordModel> records = [];
  bool loading = true;
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    try {
      records = await VipRecordModel.fetch();
      setState(() {
        loading = false;
      });
    } catch (e) {
      Util.instance.toast(e.toString());
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("开通记录"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("注意：仅包含积分兑换与在线支付方式的开通记录"),
          ),
          Expanded(
            child: loading
                ? Center(
                    child: CupertinoActivityIndicator(),
                  )
                : records.length > 0
                    ? ListView.builder(
                        itemBuilder: (context, i) {
                          return _buildRecordItem(records[i]);
                        },
                        itemCount: records.length,
                      )
                    : Center(
                        child: Text(
                          "暂无开通记录",
                          style: TextStyle(
                              color: AppTheme.of(context).placeholderColor),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(VipRecordModel record) {
    return Card(
      shape: RoundedRectangleBorder(
          side: BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "开通方式：${record.type == 1 ? '积分兑换' : '在线支付'} - ${record.cost}"),
                Text("开通时间：${record.createTime}"),
                Text("生效时间：${record.startTime}"),
                Text("过期时间：${record.isForever == 0 ? record.endTime : '永不过期'}"),
              ],
            ),
          ),
          if (record.activityId != null && (record.activityId ?? 0) > 0)
            OutlinedButton(
              onPressed: () async {
                var hide = showWeuiLoadingToast(context: context);
                String userToken =
                    await Util.instance.getStorage("user_token") ?? '';
                var res = await Util.instance.post(
                    "${Util.instance.appUrl}/vip/redemption",
                    data: {"token": userToken, "id": record.id});
                print(res);
                hide();
                if (res['code'] == 0) {
                  Util.instance.toast(res['msg']);
                } else {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: EdgeInsets.symmetric(horizontal: 50),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Text(
                                      "兑换码",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 16,
                                    ),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Text("${res['data']['code']}"),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              "关闭",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 16,
                                        ),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              Clipboard.setData(ClipboardData(
                                                  text: res['data']['code']));
                                              Util.instance.toast("兑换码已复制到剪贴板");
                                            },
                                            child: Text(
                                              "复制",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
              child: Text(
                "领取兑换码",
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
