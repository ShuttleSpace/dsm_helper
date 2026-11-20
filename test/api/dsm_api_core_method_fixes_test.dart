import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  test('dsmCoreShareCreate builds method=create', () {
    final data = dsmCoreShareCreateRequestData('share1', '/volume1');
    expect(data['api'], 'SYNO.Core.Share');
    expect(data['version'], 1);
    expect(data['method'], 'create');
    expect(data['name'], 'share1');
    expect(data['vol_path'], '/volume1');
  });

  test('dsmFileStationDeleteStatus builds method=status with taskid', () {
    final data = dsmFileStationDeleteStatusRequestData('task-123');
    expect(data['api'], 'SYNO.FileStation.Delete');
    expect(data['version'], 2);
    expect(data['method'], 'status');
    expect(data['taskid'], 'task-123');
  });

  test('dsmCoreCurrentConnectionGet builds method=get with params', () {
    final data = dsmCoreCurrentConnectionGetRequestData(
      'enum',
      offset: 0,
      limit: 50,
      start: 0,
      sortBy: 'time',
      sortDirection: 'DESC',
    );
    expect(data['api'], 'SYNO.Core.CurrentConnection');
    expect(data['version'], 1);
    expect(data['method'], 'get');
    expect(data['action'], 'enum');
    expect(data['offset'], 0);
    expect(data['limit'], 50);
    expect(data['start'], 0);
    expect(data['sort_by'], 'time');
    expect(data['sort_direction'], 'DESC');
  });
}
