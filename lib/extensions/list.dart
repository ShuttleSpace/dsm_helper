/// List 扩展
///
/// 提供列表相关的便捷方法
extension ListExt<T> on List<T> {
  /// 列表是否不为 null 且不为空
  bool get isNotEmptyOrNull => isNotEmpty;

  /// 列表是否为 null 或为空
  bool get isNullOrEmpty => isEmpty;

  /// 获取第一个元素，如果不存在则返回 null
  T? get firstOrNull {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }

  /// 获取最后一个元素，如果不存在则返回 null
  T? get lastOrNull {
    try {
      return last;
    } catch (e) {
      return null;
    }
  }

  /// 查找第一个满足条件的元素，如果不存在则返回 null
  ///
  /// [test] 测试函数
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// 查找最后一个满足条件的元素，如果不存在则返回 null
  ///
  /// [test] 测试函数
  T? lastWhereOrNull(bool Function(T) test) {
    try {
      return lastWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// 去重
  ///
  /// [key] 用于比较的键，如果提供则根据该键去重
  List<T> unique({dynamic Function(T)? key}) {
    if (key == null) {
      return toSet().toList();
    } else {
      final seen = <dynamic>{};
      return where((element) {
        final k = key(element);
        if (seen.contains(k)) {
          return false;
        } else {
          seen.add(k);
          return true;
        }
      }).toList();
    }
  }

  /// 分组
  ///
  /// [key] 用于分组的键
  Map<K, List<T>> groupBy<K>(K Function(T) key) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final k = key(element);
      map.putIfAbsent(k, () => []).add(element);
    }
    return map;
  }

  /// 过滤
  ///
  /// [test] 测试函数
  List<T> filter(bool Function(T) test) {
    return where(test).toList();
  }

  /// 映射并过滤 null 值
  ///
  /// [convert] 转换函数
  List<R> mapNotNull<R>(R? Function(T) convert) {
    return map(convert).whereType<R>().toList();
  }

  /// 拆分列表
  ///
  /// [chunkSize] 每块的大小
  List<List<T>> chunk(int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += chunkSize) {
      chunks.add(sublist(i, (i + chunkSize).clamp(0, length)));
    }
    return chunks;
  }

  /// 获取指定范围内的元素
  ///
  /// [start] 起始索引
  /// [end] 结束索引（不包含）
  List<T> slice(int start, [int? end]) {
    return sublist(start, end);
  }

  /// 判断是否包含所有指定元素
  ///
  /// [other] 要检查的元素列表
  bool containsAll(Iterable<T> other) {
    return other.every((element) => contains(element));
  }

  /// 获取随机元素
  T? random() {
    if (isEmpty) return null;
    return this[DateTime.now().millisecond % length];
  }

  /// 打乱列表
  List<T> shuffled() {
    final list = [...this];
    list.shuffle();
    return list;
  }

  /// 分离满足和不满足条件的元素
  ///
  /// [test] 测试函数
  /// 返回一个包含两个列表的元组，第一个列表包含满足条件的元素，第二个列表包含不满足条件的元素
  (List<T>, List<T>) separate(bool Function(T) test) {
    final matching = <T>[];
    final nonMatching = <T>[];
    for (final element in this) {
      if (test(element)) {
        matching.add(element);
      } else {
        nonMatching.add(element);
      }
    }
    return (matching, nonMatching);
  }

  /// 求和
  ///
  /// [selector] 选择要求和的值的函数
  num sumBy(num Function(T) selector) {
    return fold(0, (sum, element) => sum + selector(element));
  }

  /// 求平均值
  ///
  /// [selector] 选择要求平均值的值的函数
  double averageBy(num Function(T) selector) {
    if (isEmpty) return 0;
    return sumBy(selector) / length;
  }

  /// 求最大值
  ///
  /// [selector] 选择要比较的值的函数
  T? maxBy<R extends Comparable<R>>(R Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) > 0 ? a : b);
  }

  /// 求最小值
  ///
  /// [selector] 选择要比较的值的函数
  T? minBy<R extends Comparable<R>>(R Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) < 0 ? a : b);
  }
}
