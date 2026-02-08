part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "domain": "example.com",
///     "netbios_name": "EXAMPLE",
///     "base_dn": "DC=example,DC=com",
///     "status": "running"
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `domain` | string | Domain name |
/// | `netbios_name` | string | NetBIOS name |
/// | `base_dn` | string | Base Distinguished Name |
/// | `status` | string | Directory server status |
Future<Map> dsmDirectoryServerDomainGetInfo({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Domain', method: 'GetInfo', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerDomainGetInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "objects": [
///       {
///         "dn": "CN=John Doe,OU=Users,DC=example,DC=com",
///         "cn": "John Doe",
///         "objectClass": ["user", "person"],
///         "mail": "john.doe@example.com"
///       }
///     ],
///     "total": 1
///   }
/// }
Future<Map> dsmDirectoryServerDomainList(String basedn, // Base DN to search
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Domain', method: 'List', version: 1);
  data['basedn'] = basedn;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerDomainList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "user_id": 1001,
///     "username": "john.doe",
///     "name": "John Doe",
///     "email": "john.doe@example.com",
///     "status": "normal"
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// {
///   "success": true,
///   "data": {
///     "dn": "CN=John Doe,OU=Users,DC=example,DC=com"
///   }
/// }
Future<Map> dsmDirectoryServerUserCreate(
    String logonName, // User logon name
    String password, // User password
    {String? firstName, // First name
    String? lastName, // Last name
    String? email, // Email address
    String? ou, // Organizational Unit DN
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.User', method: 'Create', version: 1);
  data['logon_name'] = logonName;
  data['password'] = password;
  if (firstName != null && firstName.isNotEmpty) data['first_name'] = firstName;
  if (lastName != null && lastName.isNotEmpty) data['last_name'] = lastName;
  if (email != null && email.isNotEmpty) data['email'] = email;
  if (ou != null && ou.isNotEmpty) data['ou'] = ou;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerUserCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDirectoryServerUserModify(
    String userDn, // User Distinguished Name
    {String? firstName, // New first name
    String? lastName, // New last name
    String? email, // New email address
    String? description, // User description
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.User', method: 'Modify', version: 1);
  data['user_dn'] = userDn;
  if (firstName != null && firstName.isNotEmpty) data['first_name'] = firstName;
  if (lastName != null && lastName.isNotEmpty) data['last_name'] = lastName;
  if (email != null && email.isNotEmpty) data['email'] = email;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerUserModify: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Permanently deletes user from directory
/// - Cannot be undone
/// - User's files and permissions remain until manually removed
/// - Requires administrator privileges
Future<Map> dsmDirectoryServerUserDelete(String dn, // User Distinguished Name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.User', method: 'Delete', version: 1);
  data['dn'] = dn;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerUserDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "new_password": "TempPass123!"
///   }
/// }
///
/// **Notes:**
/// - Generates random temporary password
/// - User must change password on next login
/// - Requires administrator privileges
Future<Map> dsmDirectoryServerUserResetPassword(String username, // Username
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.User', method: 'ResetPassword', version: 1);
  data['username'] = username;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerUserResetPassword: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDirectoryServerUserChangePassword(
    String userDn, // User Distinguished Name
    String password, // New password
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.User', method: 'ChangePassword', version: 1);
  data['user_dn'] = userDn;
  data['password'] = password;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerUserChangePassword: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "group_id": 1001,
///     "groupname": "developers",
///     "description": "Development team",
///     "status": "normal"
///   }
/// }
///
/// {
///   "success": true,
///   "data": {
///     "dn": "CN=Developers,OU=Groups,DC=example,DC=com"
///   }
/// }
Future<Map> dsmDirectoryServerGroupCreate(String name, // Group name
    {String? description, // Group description
    String? ou, // Organizational Unit DN
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Group', method: 'Create', version: 1);
  data['name'] = name;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  if (ou != null && ou.isNotEmpty) data['ou'] = ou;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerGroupCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Adds user as member of group
/// - User must exist in directory
/// - Group must exist in directory
Future<Map> dsmDirectoryServerGroupAddMember(
    String userDn, // User Distinguished Name
    String groupDn, // Group Distinguished Name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Group', method: 'AddMember', version: 1);
  data['user_dn'] = userDn;
  data['group_dn'] = groupDn;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerGroupAddMember: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDirectoryServerGroupRemoveMember(
    String userDn, // User Distinguished Name
    String groupDn, // Group Distinguished Name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Group', method: 'RemoveMember', version: 1);
  data['user_dn'] = userDn;
  data['group_dn'] = groupDn;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerGroupRemoveMember: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Permanently deletes group from directory
/// - Cannot be undone
/// - Group members are not deleted
/// - Group permissions remain until manually removed
/// - Requires administrator privileges
Future<Map> dsmDirectoryServerGroupDelete(String dn, // Group Distinguished Name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Group', method: 'Delete', version: 1);
  data['dn'] = dn;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerGroupDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "sync_12345"
///   }
/// }
///
/// **Notes:**
/// - Synchronizes Synology users/groups with Directory Server
/// - Returns task ID for status monitoring
/// - Can take several minutes for large directories
///
/// ---
Future<Map> dsmDirectoryServerSyncUpdateDomain(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Sync', method: 'UpdateDomain', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerSyncUpdateDomain: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "status": "running",
///     "progress": 45,
///     "users_synced": 150,
///     "groups_synced": 25
///   }
/// }
///
/// **Notes:**
/// - Poll this endpoint to monitor sync progress
/// - Sync updates local DSM user/group database
/// - Changes from Directory Server are applied to DSM
///
/// ---
Future<Map> dsmDirectoryServerSyncGetTaskStatus(
    String taskId, // Task ID from UpdateDomain
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DirectoryServer.Sync', method: 'GetTaskStatus', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDirectoryServerSyncGetTaskStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
