import 'package:flutter/cupertino.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/resource_monitor/storage_item_card.dart';

/// 存储空间/LUN 标签页组件
class StorageTab extends StatelessWidget {
  const StorageTab({
    super.key,
    required this.loading,
    required this.data,
    required this.title,
  });

  final bool loading;
  final List data;
  final String title;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CupertinoActivityIndicator(radius: 14))
        : ListView(
            children: [
              const SizedBox(height: AppConstants.paddingMedium),
              if (data.isEmpty)
                const Center(child: Text("暂无数据"))
              else
                ...data.map((item) => StorageItemCard(item: item)),
              const SizedBox(height: AppConstants.paddingXLarge),
            ],
          );
  }
}
