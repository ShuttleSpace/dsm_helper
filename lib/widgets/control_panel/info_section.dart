import 'package:flutter/material.dart';
import 'info_card.dart';

/// 信息区块组件
/// 包含标题和内容的区块
class InfoSection extends StatelessWidget {
  /// 区块标题
  final String title;

  /// 区块内容
  final List<Widget> children;

  /// 卡片外边距
  final EdgeInsetsGeometry? margin;

  /// 标题的内边距
  final EdgeInsetsGeometry? titlePadding;

  const InfoSection({
    super.key,
    required this.title,
    required this.children,
    this.margin,
    this.titlePadding,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: titlePadding ?? const EdgeInsets.only(top: 20, left: 20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}