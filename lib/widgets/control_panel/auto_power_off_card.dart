import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/neu_picker.dart';

class AutoPowerOffCard extends StatelessWidget {
  final Map powerRecovery;
  final Map hibernation;
  final List dataList;
  final Function(bool) onAutoPowerOffEnableChanged;
  final Function(int) onAutoPowerOffTimeChanged;

  const AutoPowerOffCard({
    super.key,
    required this.powerRecovery,
    required this.hibernation,
    required this.dataList,
    required this.onAutoPowerOffEnableChanged,
    required this.onAutoPowerOffTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "在内部硬盘休眠所配置时间段后，DS 经由局域网唤醒进入待机状态（欧盟 Lot 26 规范）。",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                if (powerRecovery['wol1'] &&
                    hibernation['internal_hd_idletime'] > 0) {
                  onAutoPowerOffEnableChanged(
                      !hibernation['auto_poweroff_enable']);
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text("启用自动关机"),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 22,
                        child: hibernation['auto_poweroff_enable']
                            ? const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Color(0xffff9813),
                                size: 22,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                if (hibernation['auto_poweroff_enable']) {
                  showCupertinoModalPopup(
                      context: context,
                      builder: (context) {
                        return NeuPicker(
                          dataList
                              .getRange(1, dataList.length)
                              .map((e) => e['title'])
                              .toList()
                              .cast(),
                          value: dataList.indexWhere((element) =>
                                  element['value'] ==
                                  hibernation['auto_poweroff_time']) -
                              1,
                          onConfirm: (v) {
                            onAutoPowerOffTimeChanged(dataList[v]['value']);
                          },
                        );
                      });
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Row(
                    children: [
                      const Text("时间"),
                      const Spacer(),
                      Text(
                          "${hibernation['auto_poweroff_enable'] ? dataList.where((element) => element['value'] == hibernation['auto_poweroff_time']).first['title'] : ""}"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
