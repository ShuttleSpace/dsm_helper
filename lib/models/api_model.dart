import 'package:garden/util/api.dart';

/// maxVersion : 6
/// minVersion : 1
/// path : "auth.cgi"

class SynoApiInfo {
  SynoApiInfo({
    this.maxVersion,
    this.minVersion,
    this.path,
    this.requestFormat,
  });
  static Future<Map<String, SynoApiInfo>> fetch() async {
    Map<String, SynoApiInfo> apis = {};
    Map? res = await DsmApi.api();
    if (res?['success']) {
      res?['data'].forEach((key, value) {
        apis[key] = SynoApiInfo.fromJson(value);
      });
    }

    return apis;
  }

  SynoApiInfo.fromJson(dynamic json) {
    maxVersion = json['maxVersion'];
    minVersion = json['minVersion'];
    path = json['path'];
    requestFormat = json['requestFormat'];
  }
  num? maxVersion;
  num? minVersion;
  String? path;
  String? requestFormat;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['maxVersion'] = maxVersion;
    map['minVersion'] = minVersion;
    map['path'] = path;
    map['requestFormat'] = requestFormat;
    return map;
  }
}
