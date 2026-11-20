import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 加载状态组件
///
/// 用法示例：
/// ```dart
/// LoadingState(
///   loading: _isLoading,
///   child: ListView.builder(
///     itemBuilder: (context, index) => ItemWidget(),
///   ),
/// )
/// ```
class LoadingState extends StatelessWidget {
  /// 是否加载中
  final bool loading;

  /// 加载完成后的内容
  final Widget child;

  /// 加载指示器大小
  final double? indicatorRadius;

  /// 自定义加载指示器
  final Widget? customLoadingWidget;

  /// 空状态显示
  final bool isEmpty;

  /// 自定义空状态组件
  final Widget? emptyWidget;

  const LoadingState({
    super.key,
    required this.loading,
    required this.child,
    this.indicatorRadius = 14,
    this.customLoadingWidget,
    this.isEmpty = false,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return customLoadingWidget ??
          Center(
            child: CupertinoActivityIndicator(
              radius: indicatorRadius ?? 10,
              color: theme.colorScheme.primary,
            ),
          );
    }

    if (isEmpty) {
      return emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.square_list,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: .3),
                ),
                const SizedBox(height: 16),
                Text(
                  "暂无数据",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
    }

    return child;
  }
}
