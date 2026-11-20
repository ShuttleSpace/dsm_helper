#!/usr/bin/env dart
// ignore: dangling_library_doc_comments
/// 迁移脚本 - 自动替换 Util.instance 为新的工具类和 Store
///
/// 使用方法:
/// dart migration_script.dart lib/pages/file/file.dart

import 'dart:io';

import 'package:garden/util/log.dart';

// 替换规则
final Map<String, String> replacements = {
  // ConnectionStore 替换
  r'Util\.instance\.sid\b': 'connectionStore.sid',
  r'Util\.instance\.account\b': 'connectionStore.account',
  r'Util\.instance\.baseUrl\b': 'connectionStore.baseUrl',
  r'Util\.instance\.hostname\b': 'connectionStore.hostname',
  r'Util\.instance\.cookie\b': 'connectionStore.cookie',
  r'Util\.instance\.checkSsl\b': 'connectionStore.checkSsl',
  r'Util\.instance\.notReviewAccount\b': 'connectionStore.notReviewAccount',

  // SettingsStore 替换
  r'Util\.instance\.vibrateOn\b': 'settingsStore.vibrateOn',
  r'Util\.instance\.vibrateWarning\b': 'settingsStore.vibrateWarning',
  r'Util\.instance\.vibrateNormal\b': 'settingsStore.vibrateNormal',
  r'Util\.instance\.dashboardCardCollapseSwitch\b':
      'settingsStore.dashboardCardCollapseSwitch',
  r'Util\.instance\.dashboardCardCollapseState\b':
      'settingsStore.dashboardCardCollapseState',
  r'Util\.instance\.downloadSavePath\b': 'settingsStore.downloadSavePath',
  r'Util\.instance\.downloadWifiOnly\b': 'settingsStore.downloadWifiOnly',

  // StorageUtil 替换
  r'Util\.instance\.setStorage\s*\(': 'StorageUtil.setString(',
  r'Util\.instance\.getStorage\s*\(': 'StorageUtil.getString(',
  r'Util\.instance\.removeStorage\s*\(': 'StorageUtil.remove(',

  // UiUtil 替换
  r'Util\.instance\.toast\s*\(': 'UiUtil.toast(',
  r'Util\.instance\.vibrate\s*\(': 'UiUtil.vibrate(',

  // FormatUtil 替换
  r'Util\.instance\.formatSize\s*\(': 'FormatUtil.formatSize(',
  r'Util\.instance\.parseOpTime\s*\(': 'FormatUtil.parseOpTime(',
  r'Util\.instance\.timeLong\s*\(': 'FormatUtil.timeLong(',
  r'Util\.instance\.versionCompare\s*\(': 'FormatUtil.versionCompare(',
  r'Util\.instance\.utf8Encode\s*\(': 'FormatUtil.utf8Encode(',
  r'Util\.instance\.getAdjustColor\s*\(': 'FormatUtil.getAdjustColor(',
  r'Util\.instance\.systemVersion\s*\(': 'FormatUtil.systemVersion(',

  // FileTypeUtil 替换
  r'Util\.instance\.fileType\s*\(': 'FileTypeUtil.getFileType(',
  r'Util\.instance\.isImage\s*\(': 'FileTypeUtil.isImage(',
  r'Util\.instance\.isVideo\s*\(': 'FileTypeUtil.isVideo(',
  r'Util\.instance\.isAudio\s*\(': 'FileTypeUtil.isAudio(',
  r'Util\.instance\.isArchive\s*\(': 'FileTypeUtil.isArchive(',
};

// 需要添加的 import
final Map<String, String> requiredImports = {
  'connectionStore': "import 'package:garden/stores/connection_store.dart';",
  'settingsStore': "import 'package:garden/stores/settings_store.dart';",
  'StorageUtil': "import 'package:garden/util/storage_util.dart';",
  'UiUtil': "import 'package:garden/util/ui_util.dart';",
  'FormatUtil': "import 'package:garden/util/format_util.dart';",
  'FileTypeUtil': "import 'package:garden/util/file_type_util.dart';",
};

void main(List<String> args) {
  if (args.isEmpty) {
    Log.info('Usage: dart migration_script.dart <file_path>');
    exit(1);
  }

  String filePath = args[0];
  File file = File(filePath);

  if (!file.existsSync()) {
    Log.info('File not found: $filePath');
    exit(1);
  }

  // 读取文件内容
  String content = file.readAsStringSync();

  // 记录需要的 import
  Set<String> neededImports = {};

  // 执行替换
  replacements.forEach((pattern, replacement) {
    if (content.contains(RegExp(pattern))) {
      // 检查使用了哪个工具类或 Store
      if (replacement.contains('connectionStore')) {
        neededImports.add('connectionStore');
      } else if (replacement.contains('settingsStore')) {
        neededImports.add('settingsStore');
      } else if (replacement.contains('StorageUtil')) {
        neededImports.add('StorageUtil');
      } else if (replacement.contains('UiUtil')) {
        neededImports.add('UiUtil');
      } else if (replacement.contains('FormatUtil')) {
        neededImports.add('FormatUtil');
      } else if (replacement.contains('FileTypeUtil')) {
        neededImports.add('FileTypeUtil');
      }

      content = content.replaceAll(RegExp(pattern), replacement);
    }
  });

  // 添加 import
  if (neededImports.isNotEmpty) {
    // 找到 import 语句的位置
    int importIndex = content.indexOf('import ');
    if (importIndex != -1) {
      // 找到最后一个 import
      int lastImportIndex = importIndex;
      int currentPos = importIndex;
      while (currentPos != -1) {
        lastImportIndex = currentPos;
        currentPos = content.indexOf('import ', currentPos + 1);
      }

      // 在最后一个 import 后添加新 import
      int insertPos = content.indexOf('\n', lastImportIndex) + 1;
      String newImports =
          neededImports.map((key) => requiredImports[key]).join('\n');
      content =
          '${content.substring(0, insertPos)}$newImports\n${content.substring(insertPos)}';
    }
  }

  // 写回文件
  file.writeAsStringSync(content);

  Log.info('Migrated: $filePath');
  Log.info('Added imports: ${neededImports.join(", ")}');
}
