import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 通用信息行组件
/// 用于显示标签和对应值的行
class InfoRow extends StatelessWidget {
  /// 标签文本
  final String label;

  /// 值文本
  final String value;

  /// 标签的弹性系数
  final int labelFlex;

  /// 值的弹性系数
  final int valueFlex;

  /// 值的文本样式
  final TextStyle? valueStyle;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelFlex = 1,
    this.valueFlex = 2,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: labelFlex,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: valueFlex,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

/// 带边框的信息行组件
class BorderedInfoRow extends StatelessWidget {
  /// 标签文本
  final String label;

  /// 值文本
  final String value;

  /// 标签的弹性系数
  final int labelFlex;

  /// 值的弹性系数
  final int valueFlex;

  /// 值的文本样式
  final TextStyle? valueStyle;

  const BorderedInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelFlex = 1,
    this.valueFlex = 2,
    this.valueStyle,
  });

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
        child: InfoRow(
          label: label,
          value: value,
          labelFlex: labelFlex,
          valueFlex: valueFlex,
          valueStyle: valueStyle,
        ),
      ),
    );
  }
}