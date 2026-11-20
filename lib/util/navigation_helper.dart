import 'package:flutter/cupertino.dart';

/// 导航工具类
/// 
/// 统一管理页面跳转逻辑
/// 
/// 用法示例：
/// ```dart
/// // 跳转到新页面
/// NavigationHelper.push(context, TargetPage(), routeName: "target_page");
/// 
/// // 带返回值的跳转
/// final result = await NavigationHelper.push(context, SelectionPage());
/// 
/// // 替换当前页面
/// NavigationHelper.pushReplacement(context, NewPage());
/// 
/// // 返回上一页
/// NavigationHelper.pop(context, result);
/// ```
class NavigationHelper {
  /// 推送新页面到导航栈
  /// 
  /// [context] 上下文
  /// [page] 目标页面
  /// [routeName] 路由名称
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    return Navigator.of(context).push<T>(
      CupertinoPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  /// 推送新页面并替换当前页面
  /// 
  /// [context] 上下文
  /// [page] 目标页面
  /// [routeName] 路由名称
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      CupertinoPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  /// 推送新页面并清空导航栈
  /// 
  /// [context] 上下文
  /// [page] 目标页面
  /// [routeName] 路由名称
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
    bool Function(Route)? predicate,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      CupertinoPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
      predicate ?? (Route route) => false,
    );
  }

  /// 返回上一页
  /// 
  /// [context] 上下文
  /// [result] 返回结果
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// 返回到指定路由
  /// 
  /// [context] 上下文
  /// [routeName] 路由名称
  static void popUntil(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(
      ModalRoute.withName(routeName),
    );
  }

  /// 判断是否可以返回
  /// 
  /// [context] 上下文
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}