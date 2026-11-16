import 'dart:io';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/api/dsm_api.filestation.transfer_contract.dart';

/// 记录一次底层下载调用（savePath + 是否带 Range）。
class _DownloadCall {
  const _DownloadCall({required this.savePath, required this.headers});
  final String savePath;
  final Map<String, dynamic>? headers;

  bool get isPartial => headers?.containsKey('Range') ?? false;
}

/// 安装下载替身：把调用记入 [calls]，由 [respond] 决定写字节/返回状态。
void _fakeDownload({
  required List<_DownloadCall> calls,
  required DsmDownloadResult Function(_DownloadCall call) respond,
}) {
  dsmDownloadMetaForTesting = (
    String endpoint, {
    required String savePath,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final call = _DownloadCall(savePath: savePath, headers: headers);
    calls.add(call);
    return respond(call);
  };
}

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

  group('断点续写仅认 206 + 匹配 Content-Range', () {
    test('isResumablePartial 只接受 206 且起点等于 expectedOffset', () {
      expect(
        isResumablePartial(
          const DsmDownloadResult(
              statusCode: 206, headers: {'content-range': 'bytes 4-5/6'}),
          4,
        ),
        isTrue,
      );
      // 大小写不敏感
      expect(
        isResumablePartial(
          const DsmDownloadResult(
              statusCode: 206, headers: {'Content-Range': 'bytes 4-5/6'}),
          4,
        ),
        isTrue,
      );
      // 起点不匹配 → 不可续写
      expect(
        isResumablePartial(
          const DsmDownloadResult(
              statusCode: 206, headers: {'content-range': 'bytes 0-5/6'}),
          4,
        ),
        isFalse,
      );
      // 缺 Content-Range / 非 206 → 不可续写
      expect(
        isResumablePartial(
            const DsmDownloadResult(statusCode: 206, headers: {}), 4),
        isFalse,
      );
      expect(
        isResumablePartial(
          const DsmDownloadResult(
              statusCode: 200, headers: {'content-range': 'bytes 4-5/6'}),
          4,
        ),
        isFalse,
      );
      // 总大小未知（*）仍认偏移
      expect(
        isResumablePartial(
          const DsmDownloadResult(
              statusCode: 206, headers: {'content-range': 'bytes 4-5/*'}),
          4,
        ),
        isTrue,
      );
    });

    test('206 + 匹配 Content-Range → 仅追加分片字节到目标', () async {
      final dir = Directory.systemTemp.createTempSync('resume_206_');
      addTearDown(() {
        dsmDownloadMetaForTesting = null;
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final dest = File('${dir.path}/f.bin')..writeAsBytesSync([1, 2, 3, 4]);
      final calls = <_DownloadCall>[];
      _fakeDownload(calls: calls, respond: (call) {
        File(call.savePath).writeAsBytesSync([5, 6]);
        return const DsmDownloadResult(
          statusCode: 206,
          headers: {'content-range': 'bytes 4-5/6'},
          data: {'success': true, 'data': {}},
        );
      });

      await dsmFileStationDownload('/remote/f.bin', dest.path, resumeFrom: 4);

      expect(dest.readAsBytesSync(), [1, 2, 3, 4, 5, 6]);
      expect(File('${dest.path}.part').existsSync(), isFalse);
      expect(calls, hasLength(1));
      expect(calls.single.isPartial, isTrue);
      expect(calls.single.headers, containsPair('Range', 'bytes=4-'));
      expect(calls.single.savePath, '${dest.path}.part');
    });

    test('200（服务端忽略 Range）→ 不追加，整文件重下覆盖 dest', () async {
      final dir = Directory.systemTemp.createTempSync('resume_200_');
      addTearDown(() {
        dsmDownloadMetaForTesting = null;
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final dest = File('${dir.path}/f.bin')..writeAsBytesSync([1, 2, 3, 4]);
      final calls = <_DownloadCall>[];
      _fakeDownload(calls: calls, respond: (call) {
        // 无论 Range 与否，服务端都返回整文件（HTTP 200）。
        File(call.savePath).writeAsBytesSync([1, 2, 3, 4, 5, 6]);
        return const DsmDownloadResult(
          statusCode: 200,
          headers: {},
          data: {'success': true, 'data': {}},
        );
      });

      await dsmFileStationDownload('/remote/f.bin', dest.path, resumeFrom: 4);

      // 没有把整文件追加到半成品（否则会是 [1,2,3,4,1,2,3,4,5,6]）。
      expect(dest.readAsBytesSync(), [1, 2, 3, 4, 5, 6]);
      expect(File('${dest.path}.part').existsSync(), isFalse);
      expect(calls, hasLength(2));
      expect(calls[0].savePath, '${dest.path}.part');
      expect(calls[0].isPartial, isTrue);
      expect(calls[1].savePath, dest.path);
      expect(calls[1].isPartial, isFalse); // 回退不带 Range
    });

    test('默认 resumeFrom=0 行为不变：不带 Range，整文件直写 dest', () async {
      final dir = Directory.systemTemp.createTempSync('resume_default_');
      addTearDown(() {
        dsmDownloadMetaForTesting = null;
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final dest = File('${dir.path}/f.bin');
      final calls = <_DownloadCall>[];
      _fakeDownload(calls: calls, respond: (call) {
        File(call.savePath).writeAsBytesSync([9, 8, 7]);
        return const DsmDownloadResult(
          statusCode: 200,
          headers: {},
          data: {'success': true, 'data': {}},
        );
      });

      await dsmFileStationDownload('/remote/f.bin', dest.path);

      expect(dest.readAsBytesSync(), [9, 8, 7]);
      expect(calls, hasLength(1));
      expect(calls.single.savePath, dest.path);
      expect(calls.single.isPartial, isFalse);
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
