import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 系统信息页的网卡卡片。
class NetworkInterfaceItem extends StatelessWidget {
  final Map item;
  final int index;

  const NetworkInterfaceItem(this.item, this.index, {super.key});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20),
              child: Text(
                "局域网 ${index + 1}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final entry in [
              ('MAC 地址', item['mac']),
              ('IP 地址', item['addr']),
              ('子网掩码', item['mask']),
            ])
              Card(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.$1)),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${entry.$2}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
