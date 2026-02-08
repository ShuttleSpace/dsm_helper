/// maxVersion : 6
/// minVersion : 1
/// path : "auth.cgi"

class DsmApiInfo {
  DsmApiInfo(
    this.name, {
    this.maxVersion,
    this.minVersion,
    this.path,
  });
  DsmApiInfo.fromJson(this.name, dynamic json) {
    maxVersion = json['maxVersion'];
    minVersion = json['minVersion'];
    path = json['path'];
    requestFormat = json['requestFormat'];
  }
  num? maxVersion;
  num? minVersion;
  String? path;
  String? requestFormat;
  late String name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['maxVersion'] = maxVersion;
    map['minVersion'] = minVersion;
    map['path'] = path;
    map['requestFormat'] = requestFormat;
    map['name'] = name;
    return map;
  }
}
