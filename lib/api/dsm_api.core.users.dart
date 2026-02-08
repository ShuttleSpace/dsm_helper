part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "offset": 0,
///     "total": 3,
///     "users": [
///       {
///         "name": "admin",
///         "description": "System default user",
///         "email": "admin@example.com",
///         "expired": false,
///         "passwd_never_expire": true,
///         "groups": ["administrators"],
///         "2fa_status": "enabled"
///       }
///     ]
///   }
/// }
Future<Map> dsmCoreUserList(
    {int? offset = 0, // Starting index (default: 0)
    int? limit = -1, // Max results (default: -1 = all)
    String? sortBy = 'name', // Sort field (default: `name`)
    String? sortDirection = 'ASC', // `ASC` or `DESC` (default: `ASC`)
    String?
        additional, // Additional fields (comma-separated): description, email, expired, cannot_chg_passwd, passwd_never_expire, password_last_change, groups, 2fa_status
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.User', method: 'list', version: 1);
  if (offset != null) {
    data['offset'] = offset;
  }
  if (limit != null) {
    data['limit'] = limit;
  }
  if (sortBy != null && sortBy.isNotEmpty) {
    data['sort_by'] = sortBy;
  }
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreUserList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "user": {
///       "name": "admin",
///       "description": "System default user",
///       "email": "admin@example.com",
///       "expired": false,
///       "passwd_never_expire": true
///     }
///   }
/// }
Future<Map> dsmCoreUserGet(String name, // Username
    {String?
        additional, // Additional fields (comma-separated): description, email, expired, cannot_chg_passwd, passwd_never_expire, password_last_change, groups, 2fa_status
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.User', method: 'get', version: 1);
  data['name'] = name;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreUserGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreUserCreate(
    String name, // Username
    String password, // Password
    {String? description, // User description
    String? email, // Email address
    String? expired, // Account expiration (`never`, `date`)
    String? groups, // Group names (comma-separated)
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.User', method: 'create', version: 1);
  data['name'] = name;
  data['password'] = password;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  if (email != null && email.isNotEmpty) {
    data['email'] = email;
  }
  if (expired != null && expired.isNotEmpty) {
    data['expired'] = expired;
  }
  if (groups != null && groups.isNotEmpty) {
    data['groups'] = groups;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreUserCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreUserSet(String name, // Username
    {String? password, // New password
    String? description, // User description
    String? email, // Email address
    String? expired, // Account expiration
    // String? groups, // Group names (comma-separated)
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.User', method: 'set', version: 1);
  data['name'] = name;
  if (password != null && password.isNotEmpty) {
    data['password'] = password;
  }
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  if (email != null && email.isNotEmpty) {
    data['email'] = email;
  }
  if (expired != null && expired.isNotEmpty) {
    data['expired'] = expired;
  }
  // if (groups != null && groups.isNotEmpty) {
  //   data['groups'] = groups;
  // }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreUserSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreUserDelete(
    String name, // Username (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.User', method: 'delete', version: 1);
  data['name'] = name;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreUserDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "enable_pass_history": true,
///     "enable_strong_password": true,
///     "min_password_length": 8,
///     "password_history_count": 5
///   }
/// }
Future<Map> dsmCoreUserPasswordPolicy({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.User.PasswordPolicy', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreUserPasswordPolicy: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "enable": true,
///     "expiry_days": 90,
///     "warn_days": 7
///   }
/// }
Future<Map> dsmCoreUserPasswordExpiry({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.User.PasswordExpiry', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreUserPasswordPolicy: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
