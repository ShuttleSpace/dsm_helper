import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/setting/media_library_setting.dart';
import 'package:garden/util/media_library.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dsmFileStationPageRequestForTesting = (endpoint,
        {Map<String, dynamic>? data,
        Map<String, dynamic>? queryParameters}) async {
      if ('${data?['method']}'.contains('list_share')) {
        return {
          'success': true,
          'data': {
            'shares': [
              {
                'name': 'video',
                'path': '/video',
                'isdir': true,
                'additional': {
                  'size': 0,
                  'time': {'crtime': 0, 'mtime': 0}
                }
              }
            ]
          }
        };
      }
      return {
        'success': true,
        'data': {
          'files': [
            {
              'name': '电影',
              'path': '/video/电影',
              'isdir': true,
              'additional': {
                'size': 0,
                'time': {'crtime': 0, 'mtime': 0}
              }
            }
          ]
        }
      };
    };
  });
  tearDown(() => dsmFileStationPageRequestForTesting = null);

  testWidgets('勾选目录后按选择会加进列表', (tester) async {
    await tester.pumpWidget(
        const OKToast(child: MaterialApp(home: MediaLibrarySetting())));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsWidgets);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();

    expect(await loadMediaLibraryPaths(), ['/video']);
    expect(find.textContaining('/video'), findsWidgets);
  });
}
