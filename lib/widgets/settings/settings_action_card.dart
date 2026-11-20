import 'package:flutter/material.dart';

/// 设置页通用的「标题 + 右侧控件」卡片。
class SettingsActionCard extends StatelessWidget {
  final String label;
  final Widget trailing;

  const SettingsActionCard({
    super.key,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}
