import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_core.dart';

T useSignal<T>(ReadonlySignal<T> signal) {
  return use(_SignalHook(signal));
}

T watchSignal<T>(Signal<T> signal) {
  final value = useState(signal.value);

  useEffect(() {
    final dispose = signal.subscribe((newValue) {
      value.value = newValue;
    });
    return dispose;
  }, [signal]);

  return value.value;
}

class _SignalHook<T> extends Hook<T> {
  final ReadonlySignal<T> signal;

  const _SignalHook(this.signal);
  @override
  HookState<T, Hook<T>> createState() => _SignalHookState<T>();
}

class _SignalHookState<T> extends HookState<T, _SignalHook<T>> {
  late T _value;

  @override
  void initHook() {
    super.initHook();
    _value = hook.signal.value;
    // 监听 Signal 变化，更新状态
    effect(() {
      _value = hook.signal.value;
      setState(() {}); // 触发重建
    });
  }

  @override
  T build(BuildContext context) => _value;
}

Signal<T> useSignalState<T>(
  T initialValue, {
  String? debugLabel,
  List<Object?> keys = const [],
}) {
  return useMemoized(
    () => signal<T>(initialValue, debugLabel: debugLabel),
    keys,
  );
}

ReadonlySignal<T> useComputedSignal<T>(
  T Function() computation, {
  List<Signal> dependencies = const [],
  List<Object?>? keys,
}) {
  return useMemoized(
    () => computed(computation),
    [...dependencies.map((d) => d.value), ...?keys],
  );
}
