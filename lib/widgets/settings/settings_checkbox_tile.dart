import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/status_checkbox.dart';

/// 设置页通用的「图标 + 标题 + 勾选状态」卡片。
///
/// 点击由外层 [onTap] 处理，勾选框只展示状态；展开的子内容通过 [children] 传入。
class SettingsCheckboxTile extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;
  final String? iconAsset;
  final double iconWidth;
  final List<Widget> children;
  final double padding;
  final double fontSize;
  final double height;
  final double borderRadius;

  const SettingsCheckboxTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconAsset,
    this.iconWidth = 30,
    this.children = const [],
    this.padding = AppConstants.paddingSmall,
    this.fontSize = 16,
    this.height = 1.6,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          side: const BorderSide(),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              Row(
                children: [
                  if (iconAsset != null) ...[
                    Image.asset(iconAsset!, width: iconWidth),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(fontSize: fontSize, height: height),
                  ),
                  const Spacer(),
                  StatusCheckbox(value: value),
                ],
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
