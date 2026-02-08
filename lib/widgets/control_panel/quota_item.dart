import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/widgets/button_style.dart';
import 'package:garden/widgets/label.dart';

/// 用户配额项
class QuotaItem extends StatelessWidget {
  final Map quota;
  final VoidCallback? onTap;

  const QuotaItem({
    super.key,
    required this.quota,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: context.stadiumShapeBorder,
        margin:
            const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${quota['sharename']}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (quota['used'] != null && quota['quota'] != null)
                Row(
                  children: [
                    const Text("已用："),
                    Text(int.parse(quota['used']).formatSize()),
                    const SizedBox(width: 10),
                    const Text("/"),
                    const SizedBox(width: 10),
                    const Text("配额："),
                    Text(int.parse(quota['quota']).formatSize()),
                  ],
                ),
              if (quota['used'] != null && quota['quota'] != null)
                const SizedBox(height: 10),
              if (quota['used'] != null && quota['quota'] != null)
                Row(
                  children: [
                    const Text("状态："),
                    int.parse(quota['used']) > int.parse(quota['quota'])
                        ? const Label("超限", Colors.red, fill: true)
                        : int.parse(quota['used']) *
                                    100 ~/
                                    int.parse(quota['quota']) >
                                90
                            ? const Label("警告", Colors.orangeAccent, fill: true)
                            : const Label("正常", Colors.green, fill: true),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
