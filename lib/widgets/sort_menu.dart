import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 排序菜单组件
///
/// 用于文件列表的排序选择，支持按名称、大小、类型、日期等多种方式排序
class SortMenu extends HookWidget {
  final String sortBy;
  final String sortDirection;
  final ValueChanged<String> onSortByChanged;
  final ValueChanged<String> onSortDirectionChanged;

  const SortMenu({
    super.key,
    required this.sortBy,
    required this.sortDirection,
    required this.onSortByChanged,
    required this.onSortDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSortBy = useSignal(sortBy);
    final selectedSortDirection = useSignal(sortDirection);

    Widget buildSortOption(String value, String label) {
      return GestureDetector(
        onTap: () {
          selectedSortBy.value = value;
          onSortByChanged(value);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(label),
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: selectedSortBy.value == value
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: AppColors.primaryAction,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildDirectionOption(String value, String label) {
      return GestureDetector(
        onTap: () {
          selectedSortDirection.value = value;
          onSortDirectionChanged(value);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(label),
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: selectedSortDirection.value == value
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: AppColors.primaryAction,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(

      width: double.infinity,

      child: Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        buildSortOption("name", "名称"),
                        const SizedBox(height: 5),
                        buildSortOption("size", "大小"),
                        const SizedBox(height: 5),
                        buildSortOption("type", "文件类型"),
                        const SizedBox(height: 5),
                        buildSortOption("mtime", "修改日期"),
                        const SizedBox(height: 5),
                        buildSortOption("crtime", "创建日期"),
                        const SizedBox(height: 5),
                        buildSortOption("atime", "最近访问时间"),
                        const SizedBox(height: 5),
                        buildSortOption("posix", "权限"),
                        const SizedBox(height: 5),
                        buildSortOption("user", "拥有者"),
                        const SizedBox(height: 5),
                        buildSortOption("group", "群组"),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      buildDirectionOption("ASC", "由小至大"),
                      const SizedBox(height: 5),
                      buildDirectionOption("DESC", "由大至小"),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 22,
              ),
              OutlinedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "确定",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      ),
    ),

    );
  }
}
