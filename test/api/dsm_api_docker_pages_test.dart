import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  Map<String, dynamic>? capturedData;
  String? capturedEndpoint;

  setUp(() {
    capturedData = null;
    capturedEndpoint = null;
    dsmDockerPostForTesting = (String endpoint, {Map<String, dynamic>? data}) async {
      capturedEndpoint = endpoint;
      capturedData = data;
      return <String, dynamic>{
        'success': true,
        'data': {
          'result': [
            {'api': 'SYNO.Docker.Container', 'success': true},
          ],
        },
      };
    };
  });

  tearDown(() => dsmDockerPostForTesting = null);

  test('container overview keeps legacy compound payload and returns result',
      () async {
    final result = await dsmDockerContainerOverview();

    expect(capturedEndpoint, 'webapi/entry.cgi');
    expect(capturedData!['api'], 'SYNO.Entry.Request');
    expect(capturedData!['method'], 'request');
    expect(capturedData!['mode'], '"parallel"');
    final compound = jsonDecode(capturedData!['compound'] as String) as List;
    expect(compound.map((e) => e['api']), contains('SYNO.Docker.Container'));
    expect(compound.map((e) => e['api']),
        contains('SYNO.Docker.Container.Resource'));
    expect(compound.map((e) => e['api']),
        contains('SYNO.Core.System.Utilization'));
    expect(result.first['api'], 'SYNO.Docker.Container');
  });

  test('image overview keeps registries sub-request', () async {
    await dsmDockerImageOverview();

    final compound = jsonDecode(capturedData!['compound'] as String) as List;
    expect(compound.map((e) => e['api']), contains('SYNO.Docker.Image'));
    expect(compound.map((e) => e['api']), contains('SYNO.Docker.Registry'));
  });

  test('container action preserves signal and preserve_profile quirks',
      () async {
    await dsmDockerContainerAction('nginx', 'signal');
    expect(capturedData!['method'], 'signal');
    expect(capturedData!['signal'], 9);

    await dsmDockerContainerAction('nginx', 'delete', preserveProfile: true);
    expect(capturedData!['method'], 'delete');
    expect(capturedData!['preserve_profile'], true);
  });

  test('container log get keeps quoted date/sort and pagination', () async {
    dsmDockerPostForTesting = (String endpoint, {Map<String, dynamic>? data}) async {
      capturedData = data;
      return <String, dynamic>{'success': true, 'data': {'logs': []}};
    };

    await dsmDockerContainerLog('nginx', 'get', date: '2026-11-16');

    expect(capturedData!['method'], 'get');
    expect(capturedData!['sort_dir'], '"ASC"');
    expect(capturedData!['date'], '"2026-11-16"');
    expect(capturedData!['limit'], 1000);
    expect(capturedData!['offset'], 0);
  });

  test('failed action throws DSMException with legacy error code', () async {
    dsmDockerPostForTesting = (String endpoint, {Map<String, dynamic>? data}) async {
      return <String, dynamic>{
        'success': false,
        'error': {'code': 117},
      };
    };

    expect(
      dsmDockerContainerAction('nginx', 'signal'),
      throwsA(isA<DSMException>().having((e) => e.code, 'code', 117)),
    );
  });
}
