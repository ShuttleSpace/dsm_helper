part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "scan_enabled": true,
///     "auto_scan": true,
///     "scan_schedule": "daily",
///     "last_scan": 1732788000
///   }
/// }
Future<Map> dsmCoreSecurityScanConfGet({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SecurityScan.Conf', method: 'Get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSecurityScanConfGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "items": [
///       {
///         "id": "firewall",
///         "name": "Firewall",
///         "status": "passed",
///         "severity": "high"
///       },
///       {
///         "id": "password_strength",
///         "name": "Password Strength",
///         "status": "warning",
///         "severity": "medium"
///       }
///     ],
///     "total_passed": 15,
///     "total_warning": 3,
///     "total_failed": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `id` | string | Check item ID |
/// | `name` | string | Check item name |
/// | `status` | string | Status (`passed`, `warning`, `failed`) |
/// | `severity` | string | Severity level (`high`, `medium`, `low`) |
///
/// ---
Future<Map> dsmCoreSecurityScanStatusCheckList(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SecurityScan.Status', method: 'CheckList', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSecurityScanStatusCheckList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "scan_task_123"
///   }
/// }
///
/// **Notes:**
/// - Scan is asynchronous (use task_id to monitor)
/// - Scan checks system security configuration
/// - Results include recommendations for improvements
///
/// ---
Future<Map> dsmCoreSecurityScanOperationScan({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SecurityScan.Operation', method: 'Scan', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreSecurityScanOperationScan: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "activities": [
///       {
///         "time": 1732788000,
///         "user": "admin",
///         "ip": "192.168.1.100",
///         "result": "success",
///         "service": "DSM"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `time` | integer | Login timestamp (Unix time) |
/// | `user` | string | Username |
/// | `ip` | string | Source IP address |
/// | `result` | string | Login result (`success`, `failed`) |
/// | `service` | string | Service name (`DSM`, `SSH`, `FTP`, etc.) |
///
/// **Notes:**
/// - Security Advisor is built into DSM
/// - Provides security recommendations
/// - Monitors login activity and failed attempts
/// - Checks for malware, weak passwords, outdated packages
///
/// ---
Future<Map> dsmCoreSecurityScanLoginActivityList(
    {int? offset, int? limit, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SecurityScan.LoginActivity', method: 'List', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSecurityScanLoginActivityList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
