import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/api/dsm_api.filestation.transfer_contract.dart';

void main() {
  group('下载断点续写助手', () {
    test('无已传字节时不发 Range（整文件下载）', () {
      expect(downloadResumeRangeHeader(0), isNull);
      expect(downloadResumeRangeHeader(-1), isNull);
    });

    test('有已传字节且未完整时构造 bytes=N- Range 头', () {
      expect(
        downloadResumeRangeHeader(1024, totalBytes: 4096),
        {'Range': 'bytes=1024-'},
      );
      expect(downloadResumeRangeHeader(8 * 1024 * 1024),
          {'Range': 'bytes=8388608-'});
    });

    test('已完整（>= total）不再发 Range，避免重复落盘', () {
      expect(downloadResumeRangeHeader(4096, totalBytes: 4096), isNull);
      expect(downloadResumeRangeHeader(5000, totalBytes: 4096), isNull);
    });

    test('downloadResumeOffset 从半成品文件推导续写偏移', () {
      final f = File('${Directory.systemTemp.path}/resume_probe.bin')
        ..writeAsBytesSync(List.filled(2048, 1));
      addTearDown(() {
        if (f.existsSync()) f.deleteSync();
      });

      expect(downloadResumeOffset(f.path, totalBytes: 8192), 2048);
      // 已完整 → 从 0 重下（不追加）
      expect(downloadResumeOffset(f.path, totalBytes: 1024), 0);
      // 不存在 → 从 0 开始
      expect(
          downloadResumeOffset('${Directory.systemTemp.path}/no_such_resume_file',
              totalBytes: 8192),
          0);
    });

    test('appendPartAndCleanup 把分片字节追加到目标并删除临时分片', () {
      final dir = Directory.systemTemp.createTempSync('resume_append_');
      final dest = File('${dir.path}/dest.bin')..writeAsBytesSync([1, 2]);
      final part = File('${dir.path}/dest.bin.part')
        ..writeAsBytesSync([3, 4, 5]);
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      appendPartAndCleanup(dest.path, part.path);

      expect(dest.readAsBytesSync(), [1, 2, 3, 4, 5]);
      expect(part.existsSync(), isFalse);
    });
  });

  group('上传能力边界（降级分支）', () {
    test('未实测 v3 → 不宣称字节级续传', () {
      expect(uploadByteResumeSupported, isFalse);
    });

    test('默认上传策略为 v2 单请求（保留 Task 7 契约）', () {
      expect(selectUploadStrategy(), UploadStrategy.v2SingleRequest);
    });

    test('能力边界文案明确提示非字节级续传且可重试', () {
      expect(uploadResumeBoundaryText, contains('受 DSM 限制'));
      expect(uploadResumeBoundaryText, contains('重新上传'));
      expect(uploadResumeBoundaryText, contains('重试'));
    });
  });
}
