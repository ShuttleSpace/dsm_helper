part of 'dsm_api.dart';

/// **Notes:**
/// - Shows which services use which certificates
/// - Allows mapping certificates to specific services

/// {
///   "success": true,
///   "data": {
///     "certificates": [
///       {
///         "id": "cert_1",
///         "desc": "Default certificate",
///         "issuer": {
///           "common_name": "Synology Inc. CA",
///           "country": "TW",
///           "organization": "Synology Inc."
///         },
///         "subject": {
///           "common_name": "synology.me",
///           "sub_alt_name": ["*.synology.me", "synology.me"]
///         },
///         "user_deletable": false,
///         "renewable": true,
///         "is_default": true,
///         "valid_from": "Nov 1 00:00:00 2024 GMT",
///         "valid_till": "Nov 1 23:59:59 2025 GMT"
///       }
///     ]
///   }
/// }
Future<Map> dsmCoreCertificateList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Certificate', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreCertificateList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "certificate": {
///       "id": "cert_1",
///       "desc": "Default certificate",
///       "issuer": {
///         "common_name": "Synology Inc. CA"
///       },
///       "subject": {
///         "common_name": "synology.me"
///       }
///     }
///   }
/// }
Future<Map> dsmCoreCertificateGet(String id, {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Certificate', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreCertificateGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "id": "cert_2"
///   }
/// }
Future<Map> dsmCoreCertificateCRTImport(
    MultipartFile key, // Private key file (multipart/form-data)
    MultipartFile cert, // Certificate file (multipart/form-data)
    {MultipartFile? interCert, //  Intermediate certificate file
    String? desc,
    bool? asDefault, // Set as default certificate (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Certificate.CRT', method: 'import', version: 1)
    ..addAll({
      "key": key,
      "cert": cert,
    });
  if (interCert != null) {
    data.addAll({"inter_cert": interCert});
  }
  if (desc != null) {
    data.addAll({"desc": desc});
  }
  if (asDefault != null) {
    data.addAll({"as_default": asDefault});
  }
  final map = FormData.fromMap(data);
  final res = await _httpPost(_entryCGI, data: map, cancelToken: cancelToken);
  Log.info("dsmCoreCertificateCRTImport: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// - Returns a ZIP file containing certificate files
/// TODO: octet-stream???
Future<dynamic> dsmCoreCertificateCRTGet(String id,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Certificate.CRT', method: 'import', version: 1);
  data['id'] = id;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreCertificateCRTGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "letsencrypt_task_123"
///   }
/// }
Future<dynamic> dsmCoreCertificateLetsEncryptCreate(
    String domainList, // Domain names (comma-separated)
    String email, // Email address for Let's Encrypt
    {bool? asDefault, // Set as default certificate (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Certificate.LetsEncrypt', method: 'create', version: 1);
  data['domain_list'] = domainList;
  data['email'] = email;
  if (asDefault != null) {
    data['as_default'] = asDefault;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreCertificateLetsEncryptCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "letsencrypt_renew_123"
///   }
/// }
Future<dynamic> dsmCoreCertificateLetsEncryptRenew(
    String id, // Domain names (comma-separated)
    String email, // Email address for Let's Encrypt
    {bool? asDefault, // Set as default certificate (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Certificate.LetsEncrypt', method: 'renew', version: 1);
  data['id'] = id;
  data['email'] = email;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreCertificateLetsEncryptRenew: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "services": [
///       {
///         "display_name": "DSM Desktop Service",
///         "owner": "root",
///         "service": "default",
///         "subscriber": "system",
///         "user_setable": true,
///         "cert_id": "cert_1"
///       }
///     ]
///   }
/// }
Future<dynamic> dsmCoreCertificateServiceGet({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Certificate.Service', method: 'get', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreCertificateServiceGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
