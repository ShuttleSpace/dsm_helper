import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

/// 存储项卡片组件
class StorageItemCard extends StatelessWidget {
  const StorageItemCard({
    super.key,
    required this.item,
  });

  final Map item;

  @override
  Widget build(BuildContext context) {
    final usedSize = (item['used_size'] as num?) ?? 0;
    final totalSize = (item['total_size'] as num?) ?? 1;
    final progressValue = totalSize > 0 ? usedSize / totalSize : 0.0;

    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name'] ?? "未知",
              style: const TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              "已用: ${item['used']} / ${item['total']}",
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                color: AppColors.textPlaceholderOf(context),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppColors.progressOf(context),
            ),
          ],
        ),
      ),
    );
  }
}