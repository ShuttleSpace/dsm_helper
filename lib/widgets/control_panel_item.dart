import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/navigation_helper.dart';

/// 控制面板入口卡片组件
///
/// 用法示例：
/// ```dart
/// ControlPanelItem(
///   title: "任务管理器",
///   iconPath: "assets/control_panel/task_manager.png",
///   targetPage: TaskManagerPage(),
///   routeName: "task_manager",
/// )
/// ```
class ControlPanelItem extends StatelessWidget {
  /// 标题
  final String title;

  /// 图标路径
  final String iconPath;

  /// 目标页面
  final Widget targetPage;

  /// 路由名称
  final String? routeName;

  /// 图标高度
  final double iconHeight;

  /// 图标宽度
  final double iconWidth;

  /// 圆角半径
  final double borderRadius;

  const ControlPanelItem({
    super.key,
    required this.title,
    required this.iconPath,
    required this.targetPage,
    this.routeName,
    this.iconHeight = 30,
    this.iconWidth = 30,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        NavigationHelper.push(
          context,
          targetPage,
          routeName: routeName,
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: .1),
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                height: iconHeight,
                width: iconWidth,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
