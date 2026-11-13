import 'dart:convert';

/// 路径原样 base64 编码（不做 URL 编码），用于 /fbdownload 的 `dlink`。
/// 抓包证明 dlink 即路径的 base64。
String dsmBase64Path(String path) => base64.encode(utf8.encode(path));

/// 下载 URL：`/fbdownload/<末段>?dlink=<base64(path)>&mode=download&SynoToken=<token>`。
///
/// `baseUri` 形如 `http://192.168.8.40:5000/`（见 `connectionStore.baseUri`）。
/// /fbdownload 是否认 `Range`（多线程）待 Task 8 真机确认。
String fbDownloadUrl({
  required String baseUri,
  required String path,
  required String synoToken,
}) {
  final name = path.split('/').last;
  return '${baseUri}fbdownload/$name'
      '?dlink=${dsmBase64Path(path)}'
      '&mode=download'
      '&SynoToken=$synoToken';
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
