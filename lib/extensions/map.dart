/// Map 扩展
///
/// 提供 Map 相关的便捷方法
extension MapExt<K, V> on Map<K, V> {
  /// Map 是否不为 null 且不为空
  bool get isNotEmptyOrNull => isNotEmpty;

  /// Map 是否为 null 或为空
  bool get isNullOrEmpty => isEmpty;

  /// 获取值，如果不存在则返回 null
  V? getOrNull(K key) {
    return this[key];
  }

  /// 获取值，如果不存在则返回默认值
  ///
  /// [key] 键
  /// [defaultValue] 默认值
  V getOrDefault(K key, V defaultValue) {
    return this[key] ?? defaultValue;
  }

  /// 过滤
  ///
  /// [test] 测试函数
  Map<K, V> filter(bool Function(K, V) test) {
    return {
      for (var k in keys.where((key) => test(key, this[key] as V)))
        k: this[k] as V
    };
  }

  /// 映射值
  ///
  /// [convert] 转换函数
  Map<K, R> mapValues<R>(R Function(V) convert) {
    return map((key, value) => MapEntry(key, convert(value)));
  }

  /// 映射键
  ///
  /// [convert] 转换函数
  Map<R, V> mapKeys<R>(R Function(K) convert) {
    return map((key, value) => MapEntry(convert(key), value));
  }

  /// 获取所有键
  List<K> get keysList => keys.toList();

  /// 获取所有值
  List<V> get valuesList => values.toList();

  /// 判断是否包含所有指定的键
  ///
  /// [keys] 要检查的键列表
  bool containsAllKeys(Iterable<K> keys) {
    return keys.every((key) => containsKey(key));
  }

  /// 判断是否包含所有指定的值
  ///
  /// [values] 要检查的值列表
  bool containsAllValues(Iterable<V> values) {
    return values.every((value) => containsValue(value));
  }

  /// 移除 null 值
  Map<K, V> removeNullValues() {
    return Map.fromEntries(
      entries.where((entry) => entry.value != null),
    );
  }

  /// 合并另一个 Map
  ///
  /// [other] 要合并的 Map
  Map<K, V> merge(Map<K, V>? other) {
    if (other == null) return this;
    return {...this, ...other};
  }

  /// 获取嵌套值
  ///
  /// [keys] 键的路径
  dynamic getNestedValue(List<dynamic> keys) {
    dynamic current = this;
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// 设置嵌套值
  ///
  /// [keys] 键的路径
  /// [value] 要设置的值
  void setNestedValue(List<dynamic> keys, dynamic value) {
    Map current = this;
    for (int i = 0; i < keys.length - 1; i++) {
      final key = keys[i];
      if (!current.containsKey(key) || current[key] is! Map) {
        current[key] = {};
      }
      current = current[key] as Map;
    }
    current[keys.last] = value;
  }

  /// 转换为查询字符串
  String toQueryString() {
    return entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// 获取指定键的整数值
  int? getInt(K key) {
    final value = this[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// 获取指定键的双精度浮点数值
  double? getDouble(K key) {
    final value = this[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 获取指定键的布尔值
  bool? getBool(K key) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is int) return value != 0;
    return null;
  }

  /// 获取指定键的字符串值
  String? getString(K key) {
    final value = this[key];
    if (value is String) return value;
    return value?.toString();
  }

  /// 获取指定键的列表值
  List<T>? getList<T>(K key) {
    final value = this[key];
    if (value is List) {
      return value.cast<T>();
    }
    return null;
  }

  /// 获取指定键的 Map 值
  Map<K2, V2>? getMap<K2, V2>(K key) {
    final value = this[key];
    if (value is Map) {
      return value.cast<K2, V2>();
    }
    return null;
  }
}
