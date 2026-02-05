import 'dart:convert';

import 'package:flutter/material.dart';

/// 格式化工具类
///
/// 提供各种格式化的静态方法
class FormatUtil {
  FormatUtil._();

  /// 解析运行时间
  static String parseOpTime(String optime) {
    List items = optime.split(":");
    int days = int.parse(items[0]) ~/ 24;
    items[0] = (int.parse(items[0]) % 24).toString().padLeft(2, "0");
    items[1] = items[1].toString().padLeft(2, "0");
    items[2] = items[2].toString().padLeft(2, "0");
    return "${days > 0 ? "$days天" : ""} ${items.join(":")}";
  }

  /// 时间转时长
  static Map<String, int> timeLong(int ticket) {
    int seconds = ticket % 60;
    int minutes = ticket ~/ 60 % 60;
    int hours = ticket ~/ 60 ~/ 60;
    return {
      "hours": hours,
      "minutes": minutes,
      "seconds": seconds,
    };
  }

  /// 格式化文件大小
  static String formatSize(int bytes, {int fixed = 2, int format = 1024, bool showByte = false}) {
    if (bytes < 0) return "0 B";

    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= format && unitIndex < units.length - 1) {
      size /= format;
      unitIndex++;
    }

    if (showByte) {
      return '${size.toStringAsFixed(fixed)} ${units[unitIndex]}';
    }
    return '${size.toStringAsFixed(fixed)} ${units[unitIndex]}';
  }

  /// 版本比较
  static int versionCompare(String v1, String v2) {
    String buildNumber1 = '';
    String buildNumber2 = '';
    List version1 = v1.split("-");
    if (version1.length > 1) {
      buildNumber1 = version1[1];
    }
    List version2 = v2.split("-");
    if (version2.length > 1) {
      buildNumber2 = version2[1];
    }
    // 对比 build
    return int.parse(buildNumber1).compareTo(int.parse(buildNumber2));
  }

  /// UTF-8 编码
  static String utf8Encode(String data) {
    List<int> utf8Str = utf8.encode(data);
    String encoded = utf8Str.map((e) => e.toRadixString(16)).join("");
    return encoded;
  }

  /// 获取调整后的颜色
  static Color getAdjustColor(Color baseColor, double amount) {
    Map<String, int> colors = {
      'r': baseColor.r.toInt(),
      'g': baseColor.g.toInt(),
      'b': baseColor.b.toInt()
    };

    colors = colors.map((key, value) {
      if (value + amount < 0) {
        return MapEntry(key, 0);
      }
      if (value + amount > 255) {
        return MapEntry(key, (value + amount).floor());
      }
      return MapEntry(key, (value + amount).floor());
    });
    return Color.fromRGBO(
        colors['r'] ?? 0, colors['g'] ?? 0, colors['b'] ?? 0, 1);
  }
}
