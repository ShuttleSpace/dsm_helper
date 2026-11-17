import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 传输列表归属与状态语义的架构回归测试。
///
/// 用户症状：上传页显示「上传完成」，但传输列表里同一任务却是「失败/重试」；
/// 上传进度卡片出现在文件列表顶部而不是「传输」 tab。
void main() {
  final root = Directory.current.path;
  String read(String rel) => File('$root/$rel').readAsStringSync();

  test('transfer list lives in the transfer tab, not the file list', () {
    final downloadPage = read('lib/pages/download/download.dart');
    final filePage = read('lib/pages/file/file.dart');

    expect(downloadPage, contains('TransferList()'),
        reason: '传输 tab 必须承载上传/下载两类任务');
    expect(filePage, isNot(contains('TransferList')),
        reason: '文件列表不应再显示上传进度卡片');
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
