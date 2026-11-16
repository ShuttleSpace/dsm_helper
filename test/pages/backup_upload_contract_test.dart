import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/models/api_model.dart';

/// Locks the request shape and progress forwarding that backup.dart's
/// `onStartBackup` relies on when it calls `DsmApi.upload`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File file;
  late String filePath;
  const uploadPath = '/photo_backup';

  setUp(() {
    file = File('${Directory.systemTemp.path}/backup_upload_contract.bin');
    file.writeAsBytesSync(List<int>.filled(1234, 3));
    filePath = file.path;
    compatUploadForTesting = null;
    DsmApi.apiList = {};
  });

  tearDown(() {
    compatUploadForTesting = null;
    DsmApi.apiList = {};
    if (file.existsSync()) file.deleteSync();
  });

  test('upload builds legacy FileStation.Upload fields and forwards '
      'cancelToken / onSendProgress', () async {
    String? capturedEndpoint;
    Map<String, dynamic>? capturedParams;
    Map<String, dynamic>? capturedData;
    CancelToken? capturedToken;
    Function(int, int)? capturedProgress;
    final token = CancelToken();

    compatUploadForTesting = (
      String endpoint, {
      required Object data,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken,
      Function(int, int)? onSendProgress,
    }) async {
      capturedEndpoint = endpoint;
      capturedParams = queryParameters;
      capturedData = Map<String, dynamic>.from(data as Map);
      capturedToken = cancelToken;
      capturedProgress = onSendProgress;
      return {'success': true, 'data': {'id': 'x'}};
    };

    final progressEvents = <List<int>>[];
    final result = await DsmApi.upload(
      uploadPath,
      filePath,
      token,
      (count, total) => progressEvents.add([count, total]),
    );

    // Response is passed straight back (raw legacy envelope).
    expect(result, {'success': true, 'data': {'id': 'x'}});

    expect(capturedEndpoint, 'webapi/entry.cgi');
    expect(capturedParams!['api'], 'SYNO.FileStation.Upload');
    expect(capturedParams!['method'], 'upload');
    // No apiList entry -> legacy default minVersion 1, capped at 3.
    expect(capturedParams!['version'], 1);

    expect(capturedData!['path'], uploadPath);
    expect(capturedData!['create_parents'], true);
    expect(capturedData!['size'], file.lengthSync());
    expect(capturedData!['mtime'],
        file.lastModifiedSync().millisecondsSinceEpoch);
    expect(capturedData!['overwrite'], false);
    expect(capturedData!['file'], isA<MultipartFile>());

    expect(capturedToken, same(token));
    expect(capturedProgress, isNotNull);
    capturedProgress!(50, 100);
    expect(progressEvents, [
      [50, 100]
    ]);
  });

  test('upload caps negotiated version at 3', () async {
    Map<String, dynamic>? capturedParams;
    compatUploadForTesting = (
      String endpoint, {
      required Object data,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken,
      Function(int, int)? onSendProgress,
    }) async {
      capturedParams = queryParameters;
      return {'success': true};
    };
    DsmApi.apiList = {
      'SYNO.FileStation.Upload':
          DsmApiInfo('SYNO.FileStation.Upload', minVersion: 5),
    };

    await DsmApi.upload(uploadPath, filePath, null, (_, __) {});

    // Capped by min(apiList.minVersion, 3), even when NAS reports higher.
    expect(capturedParams!['version'], 3);
  });

  test('upload turns a DioException into the legacy failure envelope so the '
      'backup failure branch stays reachable', () async {
    final errors = <DioException>[
      DioException(
        requestOptions: RequestOptions(path: 'webapi/entry.cgi'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: 'webapi/entry.cgi'),
          statusCode: 503,
          data: {'success': false, 'error': {'code': 503}},
        ),
      ),
      DioException(
        requestOptions: RequestOptions(path: 'webapi/entry.cgi'),
        type: DioExceptionType.connectionTimeout,
        message: 'connect timeout',
      ),
    ];

    for (final error in errors) {
      compatUploadForTesting = (
        String endpoint, {
        required Object data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        Function(int, int)? onSendProgress,
      }) async {
        throw error;
      };

      final res = await DsmApi.upload(uploadPath, filePath, null, (_, __) {});

      // backup.dart:225 only checks res['success']; it must be false here,
      // otherwise the whole backup loop aborts and the item stays `running`.
      expect(res['success'], false);
      expect(res['data'], null);
      expect((res['error'] as Map)['code'], isNotNull);
      final tookFailureBranch = res['success'] != true;
      expect(tookFailureBranch, isTrue,
          reason: 'backup.dart failure branch must be reachable');
    }
  });
}
