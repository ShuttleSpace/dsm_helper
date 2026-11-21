import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 设置/表单页通用的「Card 包裹输入框」结构。
class SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final Widget? suffix;
  final double borderRadius;

  const SettingsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onEditingComplete,
    this.suffix,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
            suffixIcon: suffix,
          ),
        ),
      ),
    );
  }
}
