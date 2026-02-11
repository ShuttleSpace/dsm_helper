part of 'dsm_api.dart';

Future<Map> dsmFileStationMountMountRemote(
    {required String serverIp,
    required String account,
    required String passwd,
    required String mountPoint,
    required bool autoMount,
    String? advOpt,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Mount', method: 'mount_remote', version: 1)
    ..addAll({
      'mount_type': 'CIFS',
      'server_ip': serverIp,
      'mount_point': mountPoint,
      'user_set': false,
      'auto_mount': autoMount,
      'adv_opt': advOpt ?? '',
      'account': account,
      'passwd': passwd
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFileStationMountMountRemote: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmFileStationMountUnmount(
    {required String mountPoint,
    String? mountType = 'remote',
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Mount', method: 'unmount', version: 1)
    ..addAll({
      'mount_point': mountPoint,
      'is_mount_point': true,
      'mount_type': mountType
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFileStationMountUnmount: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
