import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/neu_picker.dart';

class HibernationSettingsCard extends StatelessWidget {
  final Map hibernation;
  final List dataList;
  final Function(int) onIdleTimeChanged;
  final Function(bool) onDeepSleepChanged;

  const HibernationSettingsCard({
    super.key,
    required this.hibernation,
    required this.dataList,
    required this.onIdleTimeChanged,
    required this.onDeepSleepChanged,
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
              "内部硬盘和外接 SATA 硬盘在闲置超过指定的时间后将进入休眠。",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      return NeuPicker(
                        dataList.map((e) => e['title']).toList().cast(),
                        value: dataList.indexWhere((element) =>
                            element['value'] ==
                            hibernation['internal_hd_idletime']),
                        onConfirm: (v) {
                          onIdleTimeChanged(dataList[v]['value']);
                        },
                      );
                    });
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
                          "${dataList.where((element) => element['value'] == hibernation['internal_hd_idletime']).first['title']}"),
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
                if (hibernation['internal_hd_idletime'] > 0) {
                  onDeepSleepChanged(
                      hibernation['sata_deep_sleep'] == 1 ? false : true);
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
                        child: Text("启动进阶硬盘休眠以将设备的耗电量降至最低"),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 22,
                        child: hibernation['sata_deep_sleep'] == 1
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
          ],
        ),
      ),
    );
  }
}
