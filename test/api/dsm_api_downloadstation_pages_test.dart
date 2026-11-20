import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  Map<String, dynamic>? capturedData;
  String? capturedEndpoint;

  setUp(() {
    capturedData = null;
    capturedEndpoint = null;
    dsmDownloadStationPostForTesting =
        (String endpoint, {Map<String, dynamic>? data}) async {
      capturedEndpoint = endpoint;
      capturedData = data;
      return <String, dynamic>{
        'success': true,
        'data': {
          'result': [
            {'api': 'SYNO.DownloadStation2.Task', 'success': true},
          ],
        },
      };
    };
    dsmDownloadStationUploadForTesting = null;
  });

  tearDown(() {
    dsmDownloadStationPostForTesting = null;
    dsmDownloadStationUploadForTesting = null;
  });

  test('overview keeps legacy compound request and returns result', () async {
    final result = await dsmDownloadStationOverview();

    expect(capturedEndpoint, 'webapi/entry.cgi');
    expect(capturedData!['api'], 'SYNO.Entry.Request');
    expect(capturedData!['mode'], '"parallel"');
    final compound = jsonDecode(capturedData!['compound'] as String) as List;
    expect(compound.map((e) => e['api']),
        contains('SYNO.DownloadStation2.Task'));
    expect(compound.map((e) => e['api']),
        contains('SYNO.DownloadStation2.Task.Statistic'));
    expect(result.first['api'], 'SYNO.DownloadStation2.Task');
  });

  test('task action sends JSON id array and method', () async {
    await dsmDownloadStation2TaskAction([1, 2], 'pause');

    expect(capturedData!['id'], '[1,2]');
    expect(capturedData!['method'], 'pause');
    expect(capturedData!['api'], 'SYNO.DownloadStation2.Task');
  });

  test('url task create trims and drops blank lines', () async {
    await dsmDownloadStation2TaskCreate('/Download', 'url',
        url: ' http://a \n\nhttp://b\n ');

    expect(jsonDecode(capturedData!['url'] as String),
        ['http://a', 'http://b']);
    expect(capturedData!['destination'], '"/Download"');
    expect(capturedData!['create_list'], true);
  });

  test('failed create throws DSMException with legacy error code', () async {
    dsmDownloadStationPostForTesting =
        (String endpoint, {Map<String, dynamic>? data}) async {
      return <String, dynamic>{
        'success': false,
        'error': {'code': 105},
      };
    };

    expect(
      dsmDownloadStation2TaskCreate('/Download', 'url', url: 'http://a'),
      throwsA(isA<DSMException>().having((e) => e.code, 'code', 105)),
    );
  });
}
