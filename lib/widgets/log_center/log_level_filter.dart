import 'package:flutter/material.dart';

/// 日志级别过滤器按钮
class LogLevelFilter extends StatelessWidget {
  final int count;
  final String type;
  final IconData iconData;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const LogLevelFilter({
    super.key,
    required this.count,
    required this.type,
    required this.iconData,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ColorFiltered(
        colorFilter: isActive
            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
            : ColorFilter.mode(Colors.grey[100]!, BlendMode.saturation),
        child: Row(
          children: [
            Icon(
              iconData,
              color: color,
              size: 20,
            ),
            const SizedBox(
              width: 5,
            ),
            Text("$count"),
            const SizedBox(
              width: 5,
            ),
          ],
        ),
      ),
    );
  }
}
