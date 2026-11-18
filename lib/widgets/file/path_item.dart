import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 文件路径面包屑项。
class FilePathItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FilePathItem({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
      ),
    );
  }
}
