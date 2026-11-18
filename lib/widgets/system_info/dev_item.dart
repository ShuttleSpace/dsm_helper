import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 系统信息页的 USB 设备卡片。
class UsbDeviceItem extends StatelessWidget {
  final Map item;

  const UsbDeviceItem(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item['cls'] == "hub" ? "USB集线器" : item['cls'],
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${item['product']}${item['producer']}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
