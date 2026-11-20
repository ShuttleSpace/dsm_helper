import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 任务详情页通用的「标签 + 值」信息行。
class DetailInfoRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool startAlign;
  final EdgeInsetsGeometry? padding;

  const DetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.startAlign = false,
    this.padding,
  });

  factory DetailInfoRow.text({
    Key? key,
    required String label,
    required String text,
    bool startAlign = false,
    EdgeInsetsGeometry? padding,
  }) {
    return DetailInfoRow(
      key: key,
      label: label,
      value: Text(text),
      startAlign: startAlign,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      margin:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          crossAxisAlignment:
              startAlign ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(width: 10),
            Expanded(child: value),
          ],
        ),
      ),
    );
  }
}
