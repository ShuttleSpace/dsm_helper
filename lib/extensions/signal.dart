import 'package:garden/util/log.dart';
import 'package:signals_flutter/signals_flutter.dart';

extension UpdateAtListSignal<T> on ListSignal<T> {
  update1(T oldValue, T Function(T oldValue) onUpdate) {
    final index = indexOf(oldValue);
    if (index == -1) {
      Log.debug('UpdateAtSignal: $oldValue not found in list');
      return;
    }
    replaceRange(index, index + 1, [onUpdate(oldValue)]);
    set(value);
  }
}

extension UpdateAtSetSignal<T> on SetSignal<T> {
  update1(T oldValue, T Function(T oldValue) onUpdate) {
    final list = toList();
    final index = list.indexOf(oldValue);
    if (index == -1) {
      Log.debug('UpdateAtSignal: $oldValue not found in set');
      return;
    }
    list.replaceRange(index, index + 1, [onUpdate(oldValue)]);
    set(list.toSet());
  }
}

extension UpdateAtMapSignal<K, V> on MapSignal<K, V> {
  update1(K key, V Function(V? oldValue) onUpdate) {
    final v = this[key];
    if (v == null) {
      Log.debug('UpdateAtSignal: $key not found in map');
    }
    value[key] = onUpdate(v);
    set(value);
  }
}
