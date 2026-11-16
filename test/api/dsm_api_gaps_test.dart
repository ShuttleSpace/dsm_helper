import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  test('gap functions exist with expected signatures', () {
    expect(dsmLogCenterHistoryList, isA<Function>());
    expect(dsmDownloadStation2TaskListGet, isA<Function>());
    expect(dsmDownloadStation2TaskListPollingDownload, isA<Function>());
    expect(dsmReward, isA<Function>());
  });

  test('dsmRewardUrl builds /reward endpoint and tolerates baseUri forms', () {
    expect(
      dsmRewardUrl('http://192.168.1.1:5000'),
      'http://192.168.1.1:5000/reward',
    );
    expect(
      dsmRewardUrl('http://192.168.1.1:5000/'),
      'http://192.168.1.1:5000/reward',
    );
    expect(
      dsmRewardUrl('https://nas.example.com:5001///'),
      'https://nas.example.com:5001/reward',
    );
  });

  test('dsmLogCenterHistoryListRequestData matches legacy logHistory payload',
      () {
    final data = dsmLogCenterHistoryListRequestData();
    expect(data['api'], 'SYNO.LogCenter.History');
    expect(data['method'], 'list');
    expect(data['version'], 1);
    expect(data['offset'], 0);
    expect(data['limit'], 50);
  });

  test(
      'dsmDownloadStation2TaskListPollingDownloadRequestData matches legacy downloadCreate payload',
      () {
    final data = dsmDownloadStation2TaskListPollingDownloadRequestData(
      'list-1',
      '/volume1/downloads/sub',
      [0, 2],
    );
    expect(data['api'], 'SYNO.DownloadStation2.Task.List.Polling');
    expect(data['method'], 'download');
    expect(data['version'], 2);
    expect(data['list_id'], '"list-1"');
    expect(data['destination'], '"volume1/downloads/sub"');
    expect(data['selected'], json.encode([0, 2]));
    expect(data['create_subfolder'], true);
  });
}
