import 'package:flutter/material.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/widgets/settings/settings_toggle_tile.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 文件列表排序菜单。
///
/// 原先是 `Files.buildSortMenu` 内联的 11 个重复勾选行，
/// 现在由数据驱动的 [SettingsToggleTile] 组成。
class FileSortMenu extends StatelessWidget {
  final Signal<String> sortBy;
  final Signal<String> sortDirection;

  const FileSortMenu({
    super.key,
    required this.sortBy,
    required this.sortDirection,
  });

  static const sortOptions = <(String, String)>[
    ('name', '名称'),
    ('size', '大小'),
    ('type', '文件类型'),
    ('mtime', '修改日期'),
    ('crtime', '创建日期'),
    ('atime', '最近访问时间'),
    ('posix', '权限'),
    ('user', '拥有者'),
    ('group', '群组'),
  ];

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      side: const BorderSide(),
      borderRadius: BorderRadius.circular(18),
    );
    final checkColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Card(
          shape: context.stadiumShapeBorder,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Card(
                  shape: shape,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          for (final option in sortOptions)
                            SettingsToggleTile(
                              label: option.$2,
                              value: sortBy.value == option.$1,
                              checkColor: checkColor,
                              shape: shape,
                              onTap: () => sortBy.value = option.$1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: shape,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        SettingsToggleTile(
                          label: "由小至大",
                          value: sortDirection.value == "ASC",
                          checkColor: checkColor,
                          shape: shape,
                          onTap: () => sortDirection.value = "ASC",
                        ),
                        const SizedBox(height: 5),
                        SettingsToggleTile(
                          label: "由大至小",
                          value: sortDirection.value == "DESC",
                          checkColor: checkColor,
                          shape: shape,
                          onTap: () => sortDirection.value = "DESC",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("确定", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
