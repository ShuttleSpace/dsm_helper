import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 传输页归属与过滤语义的回归测试。
///
/// 用户症状：上传进度卡片被「拼」在页面顶部，而不是作为 transport task
/// 在 tab 中过滤；期望 5 个 tab：全部/下载/上传/失败/完成。
void main() {
  final root = Directory.current.path;
  String read(String rel) => File('$root/$rel').readAsStringSync();

  test('transfer list lives in the transfer tab, not the file list', () {
    final downloadPage = read('lib/pages/download/download.dart');
    final filePage = read('lib/pages/file/file.dart');

    expect(downloadPage, contains('TransferList('),
        reason: '传输 tab 必须承载上传/下载两类任务');
    expect(filePage, isNot(contains('TransferList')),
        reason: '文件列表不应再显示上传进度卡片');
  });

  test('transfer page has five filter tabs', () {
    final downloadPage = read('lib/pages/download/download.dart');
    for (final label in ['全部', '下载', '上传', '失败', '完成']) {
      expect(downloadPage, contains('Tab(text: "$label")'),
          reason: '缺少传输过滤 tab: $label');
    }
    expect(downloadPage, contains('length: 5'));
  });

  test('transfer list supports type and state filters', () {
    final transferList = read('lib/widgets/transfer_list.dart');
    expect(transferList, contains('final TransferType? type'));
    expect(transferList, contains('final TransferState? state'),
        reason: '传输列表必须支持按状态过滤失败/完成');
  });

  test('bottom navigation labels the download tab as 传输', () {
    expect(read('lib/pages/home.dart'), contains("label: '传输'"));
  });

  test('upload page exposes transfer-status mapping and does not claim '
      'completion right after enqueue', () {
    final uploadPage = read('lib/pages/file/upload.dart');
    expect(uploadPage, contains('uploadStatusFromTransfer'),
        reason: '上传页状态必须由真实传输状态驱动');
    expect(uploadPage, isNot(contains('upload.status = UploadStatus.complete')),
        reason: '入队成功不等于上传完成');
  });
}
