part of "dsm_api.dart";

const _authCGI = "webapi/auth.cgi";
const _entryCGI = "webapi/entry.cgi";
const _fotoEntryCGI = "photo/webapi/entry.cgi";

List<DsmApiInfo> availableApis = [];

Map<String, dynamic> _dsmApiRequestData(
    {required String api,
    required String method,
    required int version,
    String? sid}) {
  Map<String, dynamic> data = {
    "api": api,
    "method": method,
    "version": version,
  };
  sid ??= connectionStore.sid.value;
  if (sid.isNotEmpty) data["_sid"] = sid;
  return data;
}

enum DsmErrorCode {
  unknown(100),
  noParameter(101),
  // Invalid API or method name, verify api/method is corrected, api version is supported.
  apiOrMethodNotFound(102),
  // Insufficient permissions for this operation
  insufficientPermission(103),
  versionNotSupport(104),
  loggedInSessionNoPermission(105),
  sessionTimeout(106),
  sessionInterruptedByDuplicated(107),
  uploadFailed(108),
  networkSystemBusy(109),
  networkSystemBusy1(110),
  networkSystemBusy2(111),
  preserve(112),
  preserve1(113),
  lostParameter(114),
  notAllowedUpload(115),
  notAllowedPerform(116),
  // Operation not allowed in current state
  invalidOperation(117),
  networkSystemBusy4(118),
  invalidSession(119),
  // Required parameter not provided
  missingRequiredParameter(120),
  // 120-149 preserved.
  requestSourceIPNotMatchLoginIP(150),
  // auth error
  invalidCredentials(400), // invalid credentials, check usename and password
  accountDisabled(401), // acoount disabled, enable the account int DSM
  permissionDenied(402), // permission denies, use an admin account
  twoFactorAuthRequired(
      403), // one-time password required, disable 2FA or provider OTP
  accountNotFound(404), // account doest not exist, verify username
  twoFactorAuthForced(406), // 强制两步验证码
  blockedIPSource(407), // IP 源被封锁
  expiredPasswdCannotChange(408), // 过期密码无法更改
  expiredPasswd(409), // 过期密码
  passwdMustBeChanged(410), // 密码必须更改
  // Parameter value is invalid
  invalidParameterValue(1001),
  // Parameter format is incorrect, Example: JSON string expected but plain string provided
  invalidParameterFormat(1009),
  //  Numeric parameter outside valid range. limit parameter too large
  parameterOutOfRange(1010),
  ;

  const DsmErrorCode(this.code);
  factory DsmErrorCode.valueOf(int code) {
    return DsmErrorCode.values.firstWhere((element) => element.code == code,
        orElse: () => throw Exception("Unknown error code $code"));
  }
  final int code;
}

extension MapExtension on Map {
  /// 相应是否成功
  bool succeed() {
    return this['success'] == true;
  }

  /// 响应错误码
  int? errorCodeRaw() {
    final error = this['error'];
    if (error is Map) {
      return int.tryParse(error['code']);
    }
    return null;
  }

  DsmErrorCode? errorCode() {
    final code = errorCodeRaw();
    if (code != null) {
      return DsmErrorCode.valueOf(code);
    }
    return null;
  }
}

class DSMException implements Exception {
  Object message;
  int code;
  DSMException(this.message, this.code);
  @override
  String toString() {
    return "DSMException:code: $code, $message";
  }

  static DSMException fromMap(Map res) {
    if (!res.containsKey('error')) {
      return DSMException("Unknown error", -1);
    }
    final error = res['error'];
    if (error is Map) {
      final code = error['code'];
      final message = error['message'];
      return DSMException(message ?? "Unknown error", code);
    }
    return DSMException("Unknown error", -1);
  }
}
