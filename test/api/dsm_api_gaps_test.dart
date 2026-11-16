import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  test('gap functions exist with expected signatures', () {
    // compile-time presence checks via tear-offs where possible
    expect(dsmLogCenterHistoryList, isA<Function>());
    expect(dsmDownloadStation2TaskListGet, isA<Function>());
    expect(dsmDownloadStation2TaskListPollingDownload, isA<Function>());
    expect(dsmReward, isA<Function>());
  });
}
