import 'package:flutter/material.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/label.dart';

/// eSata 设备卡片
class ESataDeviceCard extends StatelessWidget {
  final Map esata;
  final Function()? onEjectSuccess;

  const ESataDeviceCard({
    super.key,
    required this.esata,
    this.onEjectSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "${esata['dev_title']}",
                ),
                const SizedBox(
                  width: 10,
                ),
                esata['status'] == "normal"
                    ? const Label(
                        "正常",
                        Colors.green,
                        fill: true,
                      )
                    : Label(
                        esata['status'] ?? "未知",
                        Colors.red,
                        fill: true,
                      ),
                const SizedBox(
                  width: 10,
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () async {
                    var res = await DsmApi.ejectEsata(esata['dev_id']);
                    if (res['success']) {
                      UiUtil.toast("设备已退出");
                      onEjectSuccess?.call();
                    } else {
                      UiUtil.toast("设备退出失败，代码${res['error']['code']}");
                    }
                  },
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      "assets/icons/eject.png",
                    ),
                  ),
                ),
              ],
            ),
            if (esata['model'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("型号：${esata['model']}"),
              ),
            if (esata['size'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text("容量：${(int.parse(esata['size'])).formatSize()}"),
              ),
          ],
        ),
      ),
    );
  }
}
