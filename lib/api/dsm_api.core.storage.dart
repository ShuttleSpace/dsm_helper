part of 'dsm_api.dart';

const dsmCoreExternalDeviceStorageUSB = 'SYNO.Core.ExternalDevice.Storage.USB';
const dsmCoreExternalDeviceStorageESATA =
    'SYNO.Core.ExternalDevice.Storage.eSATA';

Future<Map> dsmCoreExternalDeviceList({CancelToken? cancelToken}) async {
  final compound = [
    {
      "api": dsmCoreExternalDeviceStorageUSB,
      "method": "list",
      "version": 1,
      "additional": ["all"]
    },
    {
      "api": dsmCoreExternalDeviceStorageESATA,
      "method": "list",
      "version": 1,
      "additional": ["all"]
    },
    // {"api": "SYNO.Core.ExternalDevice.Storage.EUnit", "method": "list", "version": 1},
  ];
  return await _dsmApiCall(jsonEncode(compound), cancelToken: cancelToken);
}

Future<Map> dsmCoreExternalDeviceEject(
    String deviceId, String deviceType, // 设备类型 FIXME: esata, usb
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api:
          'SYNO.Core.ExternalDevice.Storage.${deviceType == 'esata' ? 'eSATA' : 'USB'}',
      method: "eject",
      version: 1)
    ..addAll({
      'dev_id': deviceId,
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  if (!res['success'] == true) {
    throw DSMException.fromMap(res);
  }
  return res;
}

Future<Map> dsmCoreStorageDiskGetSmartTestLog(
    {required String device, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Storage.Disk', method: 'get_smart_test_log', version: 1)
    ..addAll({'device': device});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreStorageDiskGetSmartTestLog: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmCoreStorageDiskDiskTestLogGet(
    {required String device,
    String? sortBy = 'time',
    String? sortDirection = 'DESC',
    int? offset = 0,
    int? limit = 30,
    String? type = 'all',
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Storage.Disk', method: 'disk_test_log_get', version: 1)
    ..addAll({
      'device': device,
      'sort_by': sortBy,
      'sort_direction': sortDirection,
      'offset': offset,
      'limit': limit,
      'type': type
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreStorageDiskDiskTestLogGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmCoreStorageDiskDoSmartTest(
    {required String device,
    required String type, // short, long, conveyance
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Storage.Disk', method: 'do_smart_test', version: 1)
    ..addAll({'device': device, 'type': type});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreStorageDiskDoSmartTest: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmCoreStorageVolumeList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Storage.Volume', method: 'list', version: 1)
    ..addAll({'limit': -1, 'offset': 0, 'location': 'internal'});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreStorageVolumeList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
