import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/download_station/download_file_item.dart';
import 'package:garden/widgets/download_station/download_peer_item.dart';
import 'package:garden/widgets/download_station/download_tracker_item.dart';

void main() {
  testWidgets('download station list items render their data', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            const DownloadFileItem(const <String, dynamic>{
              'name': 'test.zip',
              'size_downloaded': 50,
              'size': 100,
              'priority': 'normal',
            }),
            const DownloadPeerItem(const <String, dynamic>{
              'ip': '1.2.3.4',
              'client': 'Transmission',
              'progress': 0.5,
              'speed_download': 1024,
              'speed_upload': 512,
            }),
            const DownloadTrackerItem(const <String, dynamic>{
              'url': 'http://tracker',
              'seeds': 3,
              'peers': 4,
              'status': 'Success',
            }),
          ],
        ),
      ),
    ));

    expect(find.text('test.zip'), findsOneWidget);
    expect(find.text('1.2.3.4'), findsOneWidget);
    expect(find.text('http://tracker'), findsOneWidget);
  });
}
