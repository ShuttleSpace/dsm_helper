import 'package:flutter/material.dart';
import 'info_card.dart';
import 'info_row.dart';

/// USB设备项组件
/// 用于显示单个USB设备的信息
class UsbDeviceItem extends StatelessWidget {
  /// USB设备数据
  final Map<String, dynamic> dev;

  const UsbDeviceItem({
    super.key,
    required this.dev,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: InfoRow(
        label: dev['cls'] == "hub" ? "USB集线器" : dev['cls'] ?? "",
        value: "${dev['product'] ?? ''}${dev['producer'] ?? ''}",
      ),
    );
  }
}