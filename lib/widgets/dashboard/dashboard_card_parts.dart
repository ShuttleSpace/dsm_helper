
import 'package:flutter/material.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:signals_hooks/signals_hooks.dart';

extension CardItemCollapsed on BuildContext {
  bool isCardItemCollapsed(String item) {
    if (!mounted) return false;
    return settingsStore.dashboardCardCollapseState
            .select((v) => v[item])
            .watch(this, debugLabel: "$item - CardItemCollapsed") ==
        true;
  }
}

class DashboardCardItemCollapse extends StatelessWidget {
  const DashboardCardItemCollapse(this.item, {super.key});
  final String item;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          batch(() => settingsStore.toggleCardItemCollapse(item));
        },
        icon: Icon(settingsStore.dashboardCardCollapseState
                    .select((v) => v[item])
                    .watch(context) ==
                true
            ? Icons.unfold_less
            : Icons.unfold_more));
  }
}

TextStyle dashboardRetryTextStyle(BuildContext context) {
  return TextStyle(
      fontSize: 8,
      color: Theme.brightnessOf(context) == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[300]);
}
