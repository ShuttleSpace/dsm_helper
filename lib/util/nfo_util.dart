import 'dart:convert';

import 'package:garden/extensions/string.dart';
import 'package:xml2json/xml2json.dart';

/// 解析 NFO 的 XML，返回 `movie` / `episodedetails` 节点；解不出来返回 null。
Map? parseNfoDetail(String xml) {
  try {
    final transformer = Xml2Json();
    transformer.parse(xml);
    final json = jsonDecode(transformer.toParker());
    if (json is! Map) return null;
    final detail = json['episodedetails'] ?? json['movie'];
    return detail is Map ? detail : null;
  } catch (_) {
    return null;
  }
}

/// NFO 里的 genre / director 可能是字符串、数组，或带属性的对象数组。
String joinNfoNames(dynamic value) {
  if (value == null) return '';
  final list = value is List ? value : [value];
  return list
      .map((e) => e is Map ? '${e['name'] ?? e['\$'] ?? ''}' : '$e')
      .where((e) => e.isNotBlank)
      .join('、');
}

/// NFO 的 thumb 可能是单个 URL、带 aspect 的对象，或本地文件名；这里只取远程图。
String firstNfoImage(dynamic value) {
  if (value == null) return '';
  final list = value is List ? value : [value];
  for (final e in list) {
    final url = e is Map ? '${e['\$'] ?? e['value'] ?? ''}' : '$e';
    if (url.startsWith('http')) return url;
  }
  return '';
}
