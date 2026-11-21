import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/pages/common/nas_path_picker.dart';

void main() {
  tearDown(() => dsmFileStationPageRequestForTesting = null);

  testWidgets('只在 NAS 目录里列目录与字幕，选中后返回 path', (tester) async {
    dsmFileStationPageRequestForTesting = (String endpoint,
        {Map<String, dynamic>? data,
        Map<String, dynamic>? queryParameters}) async {
      final method = data?['method'];
      if (method == '"list_share"') {
        return {
          'success': true,
          'data': {
            'shares': [
              {'name': 'video', 'path': '/video', 'isdir': true},
            ]
          }
        };
      }
      return {
        'success': true,
        'data': {
          'files': [
            {'name': '电影.mkv', 'path': '/video/电影.mkv', 'isdir': false},
            {'name': '电影.srt', 'path': '/video/电影.srt', 'isdir': false},
            {'name': '说明.txt', 'path': '/video/说明.txt', 'isdir': false},
          ]
        }
      };
    };

    List<String>? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await Navigator.of(context).push<List<String>>(
              MaterialPageRoute(
                  builder: (_) => const NasPathPicker(
                      fileExtensions: FileTypeUtil.subtitleExtensions)),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 根目录只列共享文件夹
    expect(find.text('video'), findsOneWidget);
    expect(find.text('电影.srt'), findsNothing);

    await tester.tap(find.text('video'));
    await tester.pumpAndSettle();

    // 目录里只有字幕，别的文件被过滤掉
    expect(find.text('电影.srt'), findsOneWidget);
    expect(find.text('说明.txt'), findsNothing);
    expect(find.text('电影.mkv'), findsNothing);

    await tester.tap(find.text('电影.srt'));
    await tester.pumpAndSettle();

    expect(picked, ['/video/电影.srt']);
    expect(find.byType(NasPathPicker), findsNothing);
  });

  testWidgets('多选：勾两个目录后一起确认', (tester) async {
    dsmFileStationPageRequestForTesting =
        (endpoint, {data, queryParameters}) async {
      if (data?['method'] == '"list_share"') {
        return {
          'success': true,
          'data': {
            'shares': [
              {'name': 'video', 'path': '/video', 'isdir': true},
              {'name': 'tv', 'path': '/tv', 'isdir': true},
            ]
          }
        };
      }
      return {
        'success': true,
        'data': {'files': const []}
      };
    };
    addTearDown(() => dsmFileStationPageRequestForTesting = null);

    List<String>? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await Navigator.of(context).push<List<String>>(
              MaterialPageRoute(
                  builder: (_) => const NasPathPicker(multiSelect: true)),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 多选时点目录不进去，是勾选
    await tester.tap(find.text('video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tv'));
    await tester.pumpAndSettle();
    expect(find.text('已选：/video、/tv'), findsOneWidget);

    await tester.tap(find.text('确定(2)'));
    await tester.pumpAndSettle();
    expect(picked, ['/video', '/tv']);
  });
}
