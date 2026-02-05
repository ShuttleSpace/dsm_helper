import 'package:flutter/material.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';

/// 信息页面布局组件
/// 提供统一的Tab布局框架
class InfoPageLayout extends StatelessWidget {
  /// 页面标题
  final String title;

  /// Tab标题列表
  final List<String> tabTitles;

  /// Tab控制器
  final TabController controller;

  /// Tab视图内容
  final List<Widget> tabViews;

  const InfoPageLayout({
    super.key,
    required this.title,
    required this.tabTitles,
    required this.controller,
    required this.tabViews,
  }) : assert(tabTitles.length == tabViews.length, 'Tab titles and views must have the same length');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title),
      ),
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: TabBar(
        dividerHeight: 0,
        isScrollable: true,
        controller: controller,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Theme.brightnessOf(context) == Brightness.dark
            ? Colors.white
            : Colors.black,
        unselectedLabelColor: Colors.grey,
        indicator: const BubbleTabIndicator(),
        tabs: tabTitles
            .map((title) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text(title),
                ))
            .toList(),
      ),
    );
  }
}