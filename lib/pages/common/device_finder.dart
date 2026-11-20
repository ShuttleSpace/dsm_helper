import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 设备发现：直接请求 finder/get_v2 获取局域网设备，列表供用户点选。
/// urls 依次尝试（默认 cnc 失败回退 global），可自行传入覆盖。
class DeviceFinder extends HookWidget {
  final String? title;
  final List<String> urls;

  const DeviceFinder({
    super.key,
    this.title = "设备发现",
    this.urls = const [
      "https://cnc.quickconnect.cn/finder/get_v2",
      "https://global.quickconnect.cn/finder/get_v2",
    ],
  });

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final devices = useSignal<List<Map<String, String>>>([]);
    final error = useSignal('');

    Future<void> fetch() async {
      loading.value = true;
      error.value = '';
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      try {
        for (final url in urls) {
          try {
            final res = await dio.get(url,
                options: Options(responseType: ResponseType.plain));
            final data = res.data is String ? jsonDecode(res.data) : res.data;
            final list =
                data is List ? data : (data is Map ? data['data'] : null);
            if (list is List && list.isNotEmpty) {
              devices.value = list.whereType<Map>().map(_toDevice).toList();
              return;
            }
          } catch (e) {
            Log.debug("DeviceFinder: $url failed: $e");
          }
        }
        error.value = '未找到设备，点击右上角刷新重试';
      } finally {
        loading.value = false;
      }
    }

    useEffect(() {
      fetch();
      return null;
    }, const []);

    final isLoading = loading.watch(context);
    final list = devices.watch(context);
    final err = error.watch(context);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title ?? "设备发现"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: isLoading ? null : fetch,
              child: Icon(
                Icons.refresh,
                size: 20,
                color: isLoading ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (list.isEmpty) {
          return Center(
            child: Text(
              err.isEmpty ? '未找到设备' : err,
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final device = list[index];
            final detail = [
              'IP: ${device['host']}',
              if ((device['port'] ?? '').isNotEmpty) '端口: ${device['port']}',
              if ((device['model'] ?? '').isNotEmpty) '型号: ${device['model']}',
              if ((device['version'] ?? '').isNotEmpty) 'DSM ${device['version']}',
            ].join('   ');
            return ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(device['name'] ?? '未知设备'),
              subtitle: Text(detail),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(jsonEncode(device)),
            );
          },
        );
      }),
    );
  }

  static Map<String, String> _toDevice(Map d) {
    final ipv4 = (d['ipv4_interface'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        const [];
    return {
      'name': (d['server_name'] ?? d['alias'] ?? '未知设备').toString(),
      'host': ipv4.isNotEmpty ? ipv4.first : (d['domain']?.toString() ?? ''),
      'port': (d['port'] ?? 5000).toString(),
      'https_port': (d['https_port'] ?? 5001).toString(),
      'model': (d['model'] ?? '').toString(),
      'version': (d['version'] ?? '').toString(),
      'status': (d['status'] ?? '').toString(),
      'mac': (d['mac'] ?? '').toString(),
    };
  }
}
