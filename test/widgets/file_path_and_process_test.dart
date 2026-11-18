import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/file/path_item.dart';
import 'package:garden/widgets/file/process_list.dart';

void main() {
  testWidgets('FilePathItem handles tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilePathItem(label: '视频', onTap: () => tapped = true),
      ),
    ));

    await tester.tap(find.text('视频'));
    expect(tapped, isTrue);
  });

  testWidgets('FileProcessList shows task description and progress',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FileProcessList({
          'task-1': {
            'type': 'copy',
            'path': ['/a/test.txt'],
            'data': {'dest_folder_path': '/b', 'progress': 0.5},
          },
        }),
      ),
    ));

    expect(find.textContaining('复制：'), findsOneWidget);
    expect(find.textContaining('test.txt'), findsOneWidget);
  });
}
