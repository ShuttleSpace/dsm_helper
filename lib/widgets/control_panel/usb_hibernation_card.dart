import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/neu_picker.dart';

class UsbHibernationCard extends StatelessWidget {
  final Map hibernation;
  final List dataList;
  final Function(int) onUsbIdleTimeChanged;
  final Function(bool) onEnableLogChanged;

  const UsbHibernationCard({
    super.key,
    required this.hibernation,
    required this.dataList,
    required this.onUsbIdleTimeChanged,
    required this.onEnableLogChanged,
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
              "USB 硬盘在超过设置的闲置时间后将开始休眠（仅适用于支持休眠的 USB 设备）。",
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
                            element['value'] == hibernation['usb_idletime']),
                        onConfirm: (v) {
                          onUsbIdleTimeChanged(dataList[v]['value']);
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
                          "${dataList.where((element) => element['value'] == hibernation['usb_idletime']).first['title']}"),
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
                if (hibernation['internal_hd_idletime'] > 0 ||
                    hibernation['usb_idletime'] > 0) {
                  onEnableLogChanged(!hibernation['enable_log']);
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
                        child: Text("启用硬盘休眠日志"),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 22,
                        child: hibernation['enable_log']
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
