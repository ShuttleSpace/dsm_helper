import 'package:flutter/material.dart';

/// Color 扩展
///
/// 提供颜色相关的便捷方法
extension ColorExt on Color {
  /// 设置透明度
  ///
  /// [opacity] 透明度值，范围 0.0 - 1.0
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity);
  }

  /// 变亮颜色
  ///
  /// [amount] 变亮的程度，范围 0.0 - 1.0
  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// 变暗颜色
  ///
  /// [amount] 变暗的程度，范围 0.0 - 1.0
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// 调整颜色亮度
  ///
  /// [amount] 调整的程度，正值变亮，负值变暗
  Color adjustBrightness(double amount) {
    return amount > 0 ? lighten(amount) : darken(-amount);
  }

  /// 获取颜色的互补色
  Color get complementary {
    final hsl = HSLColor.fromColor(this);
    return hsl.withHue((hsl.hue + 180) % 360).toColor();
  }

  /// 获取颜色的反转色
  Color get inverted {
    return Color.fromARGB(
      (a * 255.0).round().clamp(0, 255),
      (255.0 - r * 255.0).round().clamp(0, 255),
      (255.0 - g * 255.0).round().clamp(0, 255),
      (255.0 - b * 255.0).round().clamp(0, 255),
    );
  }

  /// 转换为十六进制字符串（不带 #）
  String toHex() {
    return '#${toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// 转换为十六进制字符串（带 #）
  String toHexString() {
    return toHex();
  }

  /// 是否为浅色
  bool get isLight {
    return computeLuminance() > 0.5;
  }

  /// 是否为深色
  bool get isDark {
    return computeLuminance() <= 0.5;
  }

  /// 混合颜色
  ///
  /// [other] 要混合的颜色
  /// [amount] 混合比例，范围 0.0 - 1.0
  Color mix(Color other, {double amount = 0.5}) {
    assert(amount >= 0 && amount <= 1);

    return Color.lerp(this, other, amount) ?? this;
  }

  Color adjust(double amount) {
    Map<String, int> colors = {'r': r.toInt(), 'g': g.toInt(), 'b': b.toInt()};

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
