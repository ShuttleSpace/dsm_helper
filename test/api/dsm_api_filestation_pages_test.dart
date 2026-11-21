import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  Map<String, dynamic>? capturedData;
  Map<String, dynamic>? capturedQuery;
  String? capturedEndpoint;

  setUp(() {
    capturedData = null;
    capturedQuery = null;
    capturedEndpoint = null;
    dsmFileStationPageRequestForTesting = (String endpoint,
        {Map<String, dynamic>? data, Map<String, dynamic>? queryParameters}) async {
      capturedEndpoint = endpoint;
      capturedData = data;
      capturedQuery = queryParameters;
      return <String, dynamic>{
        'success': true,
        'data': {
          'files': [],
          'shares': [],
          'folders': [],
          'volumes': [],
          'favorites': [],
          'finished': true,
          'taskid': 'T-1',
        },
      };
    };
  });

  tearDown(() => dsmFileStationPageRequestForTesting = null);

  test('file list keeps legacy POST envelope and sort fields', () async {
    final data = await dsmFileStationListForPage('/Download',
        sortBy: 'name', sortDirection: 'desc');

    expect(capturedEndpoint, 'webapi/entry.cgi');
    expect(data['files'], isEmpty);
    expect(capturedData!['method'], '"list"');
    expect(capturedData!['folder_path'], '/Download');
    expect(capturedData!['sort_by'], '"name"');
    expect(capturedData!['sort_direction'], '"desc"');
    expect(capturedData!['limit'], 5000);
  });

  test('virtual folders and remote links keep node/type', () async {
    await dsmFileStationVirtualFolderSmbForPage();
    expect(capturedData!['node'], 'fm_rf_root');
    expect(capturedData!['type'], '["cifs","nfs"]');

    await dsmFileStationVirtualFolderForPage('ftp');
    expect(capturedData!['node'], '"ftp"');
    expect(capturedData!['type'], '"ftp"');
  });

  test('create folder and rename keep legacy GET with quoted fields', () async {
    await dsmFileStationCreateFolderForPage('/a', 'new');
    expect(capturedQuery!['folder_path'], '"/a"');
    expect(capturedQuery!['name'], '"new"');
    expect(capturedQuery!['force_parent'], 'false');

    await dsmFileStationRenameForPage('/a/b', 'renamed');
    expect(capturedQuery!['api'], '"SYNO.FileStation.Rename"');
    expect(capturedQuery!['path'], '"/a/b"');
    expect(capturedQuery!['name'], '"renamed"');
  });

  test('copy/move and delete keep JSON path payloads', () async {
    await dsmFileStationCopyMoveStartForPage(['/a', '/b'], '/c', true);
    expect(capturedData!['path'], '["/a","/b"]');
    expect(capturedData!['remove_src'], true);
    expect(capturedData!['method'], '"start"');

    await dsmFileStationDeleteStartForPage(['/a']);
    expect(capturedData!['path'], '["/a"]');
    expect(capturedData!['accurate_progress'], 'true');
  });

  test('failure throws DSMException with legacy code', () async {
    dsmFileStationPageRequestForTesting = (String endpoint,
        {Map<String, dynamic>? data, Map<String, dynamic>? queryParameters}) async {
      return <String, dynamic>{
        'success': false,
        'error': {'code': 117},
      };
    };

    expect(
      dsmFileStationListForPage('/a'),
      throwsA(isA<DSMException>().having((e) => e.code, 'code', 117)),
    );
  });
}
