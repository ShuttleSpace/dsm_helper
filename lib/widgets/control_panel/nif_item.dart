import 'package:flutter/material.dart';
import 'info_card.dart';
import 'info_row.dart';

/// 网络接口项组件
/// 用于显示单个网络接口的详细信息
class NifItem extends StatelessWidget {
  /// 网络接口数据
  final Map<String, dynamic> nif;

  /// 网络接口索引（用于显示标题）
  final int index;

  const NifItem({
    super.key,
    required this.nif,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
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
          BorderedInfoRow(label: "MAC 地址", value: nif['mac'] ?? ""),
          BorderedInfoRow(label: "IP 地址", value: nif['addr'] ?? ""),
          BorderedInfoRow(label: "子网掩码", value: nif['mask'] ?? ""),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}