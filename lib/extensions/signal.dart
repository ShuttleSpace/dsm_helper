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
  }
}

extension UpdateAtSetSignal<T> on SetSignal<T> {
  update1(T oldValue, T Function() onUpdate) {
    final ov = this;
    value = {...ov, onUpdate()};
  }
}

extension UpdateAtMapSignal<K, V> on MapSignal<K, V> {
  update1(K key, V Function(V?) onUpdate) {
    final ov = this;
    value = {...ov, key: onUpdate(ov[key])};
  }
}
