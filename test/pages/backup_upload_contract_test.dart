import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/models/api_model.dart';

/// Locks the request shape and progress forwarding that backup.dart's
/// `onStartBackup` relies on when it calls `dsmFileStationUploadForPage`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File file;
  late String filePath;
  const uploadPath = '/photo_backup';

  setUp(() {
    file = File('${Directory.systemTemp.path}/backup_upload_contract.bin');
    file.writeAsBytesSync(List<int>.filled(1234, 3));
    filePath = file.path;
    dsmFileStationUploadPageForTesting = null;
    availableApis.clear();
  });

  tearDown(() {
    dsmFileStationUploadPageForTesting = null;
    availableApis.clear();
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

    dsmFileStationUploadPageForTesting = (
      String endpoint, {
      Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken,
      Function(int, int)? onSendProgress,
    }) async {
      capturedEndpoint = endpoint;
      capturedParams = queryParameters;
      capturedData = Map<String, dynamic>.from(data ?? const {});
      capturedToken = cancelToken;
      capturedProgress = onSendProgress;
      return {'success': true, 'data': {'id': 'x'}};
    };

    final progressEvents = <List<int>>[];
    final result = await dsmFileStationUploadForPage(
      uploadPath,
      filePath,
      token,
      (count, total) => progressEvents.add([count, total]),
    );

    expect(result, {'id': 'x'});

    expect(capturedEndpoint, 'webapi/entry.cgi');
    expect(capturedParams!['api'], 'SYNO.FileStation.Upload');
    expect(capturedParams!['method'], 'upload');
    // No availableApis entry -> legacy default minVersion 1, capped at 3.
    expect(capturedParams!['version'], 1);

    expect(capturedData!['path'], uploadPath);
    expect(capturedData!['create_parents'], true);
    expect(capturedData!['size'], file.lengthSync());
    expect(capturedData!['mtime'],
        file.lastModifiedSync().millisecondsSinceEpoch);
    expect(capturedData!['overwrite'], false);
    expect(capturedData!['file'], isA<MultipartFile>());

    expect(capturedToken, same(token));
    capturedProgress!(10, 100);
    expect(progressEvents, [
      [10, 100]
    ]);
  });

  test('upload version is capped at 3 when NAS reports higher', () async {
    Map<String, dynamic>? capturedParams;
    dsmFileStationUploadPageForTesting = (
      String endpoint, {
      Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken,
      Function(int, int)? onSendProgress,
    }) async {
      capturedParams = queryParameters;
      return {'success': true};
    };
    availableApis.add(
      DsmApiInfo('SYNO.FileStation.Upload', minVersion: 5),
    );

    await dsmFileStationUploadForPage(uploadPath, filePath, null, (_, __) {});

    expect(capturedParams!['version'], 3);
  });

  test('upload surfaces transport failures as exceptions so backup.dart '
      'failure branch stays reachable', () async {
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
      dsmFileStationUploadPageForTesting = (
        String endpoint, {
        Map<String, dynamic>? data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        Function(int, int)? onSendProgress,
      }) async {
        throw error;
      };

      expect(
        dsmFileStationUploadForPage(uploadPath, filePath, null, (_, __) {}),
        throwsA(isNotNull),
        reason: 'backup.dart catch branch must be reachable',
      );
    }
  });
}
