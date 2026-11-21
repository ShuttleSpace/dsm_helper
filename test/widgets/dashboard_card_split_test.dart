import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard cards are split into focused widget files', () {
    final root = Directory.current.path;
    final barrel = File('$root/lib/pages/dashborad/dashboard_cards.dart')
        .readAsStringSync();

    expect(barrel, contains('export '));
    expect(barrel, isNot(contains('class Dashboard')),
        reason: '旧的大文件应只保留 barrel 导出');

    for (final name in [
      'system_health_card.dart',
      'connection_log_card.dart',
      'task_scheduler_card.dart',
      'recent_log_card.dart',
      'resource_monitor_card.dart',
      'storage_usage_card.dart',
      'file_change_log_card.dart',
      'dashboard_card_parts.dart',
    ]) {
      expect(File('$root/lib/widgets/dashboard/$name').existsSync(), isTrue,
          reason: '缺少拆分后的组件文件: $name');
      expect(barrel, contains(name));
    }
  });
}
