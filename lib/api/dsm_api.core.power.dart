part of 'dsm_api.dart';

Future<Map> dsmCoreSystemPower(String method, // shutdown, reboot
    {required bool force,
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.System', method: method, version: 1)
        ..addAll({'force': force, 'local': true});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreSystemPower: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreHardwarePowerScheduleSave(
    {required List poweronTasks,
    required List poweroffTasks,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Hardware.PowerSchedule', method: 'save', version: 1)
    ..addAll({
      'poweron_tasks': jsonEncode(poweronTasks),
      'poweroff_tasks': jsonEncode(poweroffTasks)
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreHardwarePowerScheduleSave: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreHardwareHibernationSet(
    {int? internalHdIdletime,
    bool? sataDeepSleep,
    int? usbIdletime,
    bool? enableLog,
    bool? autoPoweroffEnable,
    int? autoPoweroffTime,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Hardware.Hibernation', method: 'set', version: 1)
    ..addAll({
      'internal_hd_idletime': internalHdIdletime,
      'sata_deep_sleep': sataDeepSleep,
      'ignore_netbios_broadcast': false,
      'usb_idletime': usbIdletime,
      'enable_log': enableLog,
      'auto_poweroff_enable': autoPoweroffEnable,
      'auto_poweroff_time': autoPoweroffTime
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreHardwareHibernationSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
