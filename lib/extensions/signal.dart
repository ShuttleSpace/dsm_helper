import 'dart:async';
import 'dart:convert';

import 'package:garden/util/log.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart' as sig;

const kSignalHiveBoxName = 'signal';

extension PersistentSignalExt<T> on sig.Signal<T> {
  Future<void> save(String key,
      {bool useHive = false, bool useSP = true}) async {
    if (useHive && useSP) {
      throw 'only can use one storage type!';
    }
    if (useSP) {
      await _saveToSP(key);
    } else if (useHive) {
      await _saveToHive(key);
    }
  }

  Future<void> _saveToHive(String key) async {
    final box = await Hive.openBox(kSignalHiveBoxName);
    await box.put(key, value);
  }

  Future<void> _saveToSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value as String);
    } else if (value is int) {
      await prefs.setInt(key, value as int);
    } else if (value is double) {
      await prefs.setDouble(key, value as double);
    } else if (value is bool) {
      await prefs.setBool(key, value as bool);
    } else if (T == List) {
      await prefs.setStringList(
          key, (T as List).map((t) => jsonEncode(t)).toList());
    } else if (T == Set) {
      await prefs.setStringList(
          key, (T as Set).map((t) => jsonEncode(t)).toList());
    } else if (T == Map) {
      await prefs.setString(key, jsonEncode(value));
    } else if (T == Enum) {
      await prefs.setString(key, jsonEncode(value));
    } else {
      String valueToSave;
      try {
        valueToSave = jsonEncode(value);
      } on Exception catch (e) {
        valueToSave = value.toString();
        kTalker.warning(e);
      }
      await prefs.setString(key, valueToSave);
    }
  }

  Future<void> read(String key,
      {bool useHive = false, bool useSP = true}) async {
    if (useHive && useSP) {
      throw 'only can use one storage type!';
    }
    if (useSP) {
      await _readFromSP(key);
    } else if (useHive) {
      await _readFromHive(key);
    }
  }

  Future<void> _readFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    dynamic stored = prefs.getString(key);
    if (stored != null && stored is String) {
      try {
        value = jsonDecode(stored) as T;
      } catch (e) {
        value = stored as T;
        kTalker.warning(e);
      }
      return;
    }
    stored = prefs.getInt(key);
    if (stored != null && stored is int) {
      value = stored as T;
    }
    stored = prefs.getBool(key);
    if (stored != null && stored is bool) {
      value = stored as T;
    }
    stored = prefs.getDouble(key);
    if (stored != null && stored is double) {
      value = stored as T;
    }
    stored = prefs.getStringList(key);
    if (stored != null && stored is List) {
      final v = stored.map((t) => jsonDecode(t));
      if (T is Set) {
        value = Set.from(v) as T;
      } else {
        value = v as T;
      }
    }
  }

  Future<void> _readFromHive(String key) async {
    final box = await Hive.openBox(kSignalHiveBoxName);
    final stored = box.get(key);
    value = stored as T;
  }
}

extension UpdateAtListSignal<T> on sig.ListSignal<T> {
  update1(T oldValue, T Function(T oldValue) onUpdate) {
    final index = indexOf(oldValue);
    if (index == -1) {
      Log.debug('UpdateAtSignal: $oldValue not found in list');
      return;
    }
    replaceRange(index, index + 1, [onUpdate(oldValue)]);
  }
}

extension UpdateAtSetSignal<T> on sig.SetSignal<T> {
  update1(T oldValue, T Function() onUpdate) {
    final ov = this;
    value = {...ov, onUpdate()};
  }
}

extension UpdateAtMapSignal<K, V> on sig.MapSignal<K, V> {
  update1(K key, V Function(V?) onUpdate) {
    final ov = this;
    value = {...ov, key: onUpdate(ov[key])};
  }
}

/// 创建持久化 Signal
sig.Signal<T> persistentSignal<T>({
  required String key,
  required T initialValue,
  T Function(String)? fromJson,
  String Function(T)? toJson,
}) {
  final v = sig.signal(initialValue);
  // 从持久化存储中读取初始值
  _loadFromStorage(key, initialValue, v, fromJson);
  // 监听变化并自动保存
  sig.effect(() {
    final value = v.value;
    _saveToStorage(key, value, toJson);
  });
  return v;
}

void _loadFromStorage<T>(
  String key,
  T initialValue,
  sig.Signal<T> signal,
  T Function(String)? fromJson,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(key);

    if (stored != null) {
      if (fromJson != null) {
        signal.value = fromJson(stored);
      } else if (T == String) {
        signal.value = stored as T;
      } else if (T == int) {
        signal.value = int.parse(stored) as T;
      } else if (T == double) {
        signal.value = double.parse(stored) as T;
      } else if (T == bool) {
        signal.value = (stored == 'true') as T;
      }
    }
  } catch (e) {
    Log.error('加载持久化数据失败: $e');
  }
}

void _saveToStorage<T>(
  String key,
  T value,
  String Function(T)? toJson,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String valueToSave;

    if (toJson != null) {
      valueToSave = toJson(value);
    } else if (value is String) {
      valueToSave = value;
    } else if (value is int || value is double || value is bool) {
      valueToSave = value.toString();
    } else {
      valueToSave = value.toString();
    }

    await prefs.setString(key, valueToSave);
  } catch (e) {
    Log.error('保存持久化数据失败: $e');
  }
}
