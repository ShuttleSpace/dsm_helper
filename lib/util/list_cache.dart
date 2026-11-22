import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 列表快照缓存：内存命中立刻返回，磁盘快照跨启动复用，网络结果负责回写。
///
/// 读到的快照可能已经过期，调用方应先展示快照再后台刷新（stale-while-revalidate）；
/// 返回 null 表示没有快照，调用方走原来的"加载中"流程。
class ListCache {
  ListCache._();

  /// 超过该时长的磁盘快照直接丢弃；新鲜度靠每次打开时的后台刷新保证。
  static const Duration maxAge = Duration(days: 7);

  static final Map<String, Object?> _mem = {};

  @visibleForTesting
  static Directory? rootForTest;

  /// 快照按 (NAS 地址, 账号) 隔离，换服务器或换账号不会读到别的账号的数据。
  static String _scoped(String key) =>
      '${connectionStore.baseUri.value}#${connectionStore.account.value}#$key';

  static Future<Directory> _root() async =>
      rootForTest ??
      Directory(p.join(
          (await getApplicationSupportDirectory()).path, 'list_cache'));

  static Future<File> _file(String scoped) async {
    final dir = await _root();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final name =
        scoped.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x3fffffff);
    return File(p.join(dir.path, '$name.json'));
  }

  static Future<Object?> read(String key) async {
    final scoped = _scoped(key);
    if (_mem.containsKey(scoped)) return _mem[scoped];
    try {
      final file = await _file(scoped);
      if (!file.existsSync()) return null;
      final data = json.decode(await file.readAsString()) as Map<String, dynamic>;
      // 文件名是哈希，撞车时落盘的 key 对不上，当未命中处理。
      if (data['k'] != scoped) return null;
      final saved = DateTime.fromMillisecondsSinceEpoch(data['t'] as int);
      if (DateTime.now().difference(saved) > maxAge) return null;
      return _mem[scoped] = data['v'];
    } catch (_) {
      return null;
    }
  }

  /// 写内存立即生效，落盘失败只影响下次冷启动，因此不向调用方抛错。
  static Future<void> write(String key, Object? value) async {
    final scoped = _scoped(key);
    _mem[scoped] = value;
    try {
      final file = await _file(scoped);
      await file.writeAsString(json.encode({
        'k': scoped,
        't': DateTime.now().millisecondsSinceEpoch,
        'v': value,
      }));
    } catch (_) {}
  }

  /// 登出/切换账号时清空内存快照。
  static void clear() {
    _mem.clear();
  }
}
