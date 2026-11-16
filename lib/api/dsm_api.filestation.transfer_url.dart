/// 下载 URL：官方 `SYNO.FileStation.Download`。
///
/// 私有端点 `/fbdownload` 在 DSM 7.3.2 上鉴权失效（实测返回 119 unauth / 38B
/// 错误 JSON，被当成文件存成 36~38B）；官方 webapi 用 `_sid` 即可取到真文件。
String fbDownloadUrl({
  required String baseUri,
  required String path,
  required String sid,
  int version = 2,
}) {
  final base = baseUri.replaceFirst(RegExp(r'/+$'), '');
  return '$base/webapi/entry.cgi'
      '?api=SYNO.FileStation.Download'
      '&method=download'
      '&version=$version'
      '&path=${Uri.encodeComponent(path)}'
      '&mode=download'
      '&_sid=$sid';
}

/// 上传入口 URL：`webapi/entry.cgi?api=SYNO.FileStation.Upload&method=upload&version=<v>&SynoToken=<token>`。
String uploadEntryUrl({
  required String baseUri,
  required String synoToken,
  int version = 2,
}) {
  return '${baseUri}webapi/entry.cgi'
      '?api=SYNO.FileStation.Upload'
      '&method=upload'
      '&version=$version'
      '&SynoToken=$synoToken';
}
