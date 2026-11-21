part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "offset": 0,
///     "total": 3,
///     "groups": [
///       {
///         "name": "administrators",
///         "gid": 101,
///         "description": "System default admin group"
///       },
///       {
///         "name": "users",
///         "gid": 100,
///         "description": "System default group"
///       }
///     ]
///   }
/// }
Future<Map> dsmCoreGroupList(
    {int? offset = 0, // Starting index (default: 0)
    int? limit = -1, // Max results (default: -1 = all)
    bool? nameOnly = false, // Return only names (default: false)
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Group', method: 'list', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (nameOnly != null) data['name_only'] = nameOnly;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "group": {
///       "name": "administrators",
///       "gid": 101,
///       "description": "System default admin group"
///     }
///   }
/// }
Future<Map> dsmCoreGroupGet(String name, // Group name
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Group', method: 'get', version: 1);
  data['name'] = name;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreGroupCreate(String name, // Group name
    {String? description, // Group description
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Group', method: 'create', version: 1);
  data['name'] = name;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreGroupSet(String name, // Group name
    {String? newName, // New group name
    String? description, // Group description
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Group', method: 'set', version: 1);
  data['name'] = name;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  if (newName != null && newName.isNotEmpty) {
    data['new_name'] = newName;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreGroupDelete(
    String name, // Group name (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Group', method: 'delete', version: 1);
  data['name'] = name;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "members": ["admin", "user1", "user2"]
///   }
/// }
Future<Map> dsmCoreGroupMemberList(String group, // Group name
    {bool? inGroup, // List members (true) or non-members (false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Group.Member', method: 'list', version: 1);
  data['group'] = group;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupMemberList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreGroupMemberAdd(
    String group, // Group name
    String users, // Usernames (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Group.Member', method: 'add', version: 1);
  data['group'] = group;
  data['users'] = users;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupMemberAdd: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreGroupMemberRemove(
    String group, // Group name
    String users, // Usernames (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Group.Member', method: 'add', version: 1);
  data['group'] = group;
  data['users'] = users;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreGroupMemberRemove: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
