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

/// (module, error code, error message, error description/solution)
const Map<String, Map<int, (String, String?)>> _dsmApiErrorMap = {
  "common": {
    100: ("Unknown error", null),
    101: ("Invalid parameter", "Check parameter value"),
    102: ("Invalid API or method name", "Verify API or method"),
    103: (
      "Permission Denied",
      "Insufficient permissions for this operation. Provider admin account or grant permission"
    ),
    104: ("Not supported version", "Verify API version"),
    105: (
      "Permission denied ",
      "Use an admin account or Grant admin privileges or use an admin account"
    ),
    106: ("Session timeout", "Relogin or refresh session"),
    108: ("uploadFailed", null),
    109: ("networkSystemBusy", null),
    110: ("networkSystemBusy1", null),
    111: ("networkSystemBusy2", null),
    112: ("preserve", null),
    113: ("preserve1", null),
    114: ("lostParameter", null),
    115: ("notAllowedUpload", null),
    116: ("notAllowedPerform", null),
    117: (
      "Invalid Operation",
      "Operation not allowed in current state. Check resource state before operation or Wait for current operation to complete"
    ),
    118: ("networkSystemBusy4", null),
    119: ("invalidSession", null),
    120: ("Missing Required Parameter", "Check required parameters"),
    150: ("requestSourceIPNotMatchLoginIP", null),
    400: ("Invalid parameter", "Check parameter value"),
    401: ("Unknown error", "Check parameter value"),
  },
  "core": {
    107: ("Multiple login detected", "Check login IP"),
    400: ("Invalid credentials", "Check username and password"),
    401: ("Account disabled", "Enable the account in DSM"),
    402: (
      "Permission denied",
      "Use an admin account or Grant admin privileges or use an admin account"
    ),
    403: ("One-time password required", "Disable 2FA or provide OTP"),
    404: ("Account Not Found", "Verify the username exists in DSM"),
    406: ("twoFactorAuthForced", null),
    407: ("blockedIPSource", null),
    408: ("expiredPasswdCannotChange", null),
    409: ("expiredPasswd", null),
    410: ("passwdMustBeChanged", null),
    1001: (
      "Invalid Parameter Value",
      "Parameter value is invalid.Verify parameter value exists or Ensure value is correct type"
    ),
    1009: ("Invalid Parameter Format", "Parameter format is incorrect."),
    1010: (" Parameter Out of Range", "Numeric parameter outside valid range"),
  },
};

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
}

class DSMException implements Exception {
  Object message;
  int code;
  Object? descriptionOrSolution;
  final Map<String, dynamic>? rawError;
  final Map<String, dynamic>? rawResponse;
  DSMException(this.message, this.code,
      {this.descriptionOrSolution, this.rawError, this.rawResponse});
  @override
  String toString() {
    return "DSMException:code: $code, $message,$descriptionOrSolution";
  }

  static DSMException fromMap(Map res, {String? module}) {
    final rawResponse = Map<String, dynamic>.from(res);
    final error = res['error'];
    final rawError = error is Map ? Map<String, dynamic>.from(error) : null;
    if (!res.containsKey('error')) {
      return DSMException("Unknown error", -1,
          rawError: rawError, rawResponse: rawResponse);
    }
    if (error is Map) {
      int code = error['code'];
      (String, String?)? errorInfo;
      if (module != null) {
        errorInfo = _dsmApiErrorMap[module]?[code];
      }
      errorInfo ??=
          _dsmApiErrorMap['common']?[code] ?? _dsmApiErrorMap['core']?[code];
      if (errorInfo != null) {
        return DSMException(errorInfo.$1, code,
            descriptionOrSolution: errorInfo.$2,
            rawError: rawError,
            rawResponse: rawResponse);
      }
    }
    return DSMException("Unknown error", -1,
        rawError: rawError, rawResponse: rawResponse);
  }
}

/// 同时发起多个请求
Future<Map> _dsmApiCall(
    String compound, // JSON Array,[{api, method, version, additional}]
    {String endpoint = _entryCGI,
    int? version,
    String mod = 'sequential', // parallel or sequential
    bool? stopWhenError,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Entry.Request', method: 'request', version: version ?? 1)
    ..addAll({
      'mod': mod, // FIXME: parallel???
      'compound': compound,
      'stop_when_error': stopWhenError ?? false,
    });
  return await _httpGet(endpoint,
      queryParameters: data, cancelToken: cancelToken);
}
