/// 下载 URL：官方 `SYNO.FileStation.Download`。
///
/// 私有端点 `/fbdownload` 在 DSM 7.3.2 上鉴权失效（实测返回 119 unauth / 38B
/// 错误 JSON，被当成文件存成 36~38B）；官方 webapi 用 `_sid` 即可取到真文件。
///
/// [mode] 默认 `download`（下载落盘）；预览内联取流传 `open`。
String fbDownloadUrl({
  required String baseUri,
  required String path,
  required String sid,
  int version = 2,
  String mode = 'download',
}) {
  final base = baseUri.replaceFirst(RegExp(r'/+$'), '');
  return '$base/webapi/entry.cgi'
      '?api=SYNO.FileStation.Download'
      '&method=download'
      '&version=$version'
      '&path=${Uri.encodeComponent(path)}'
      '&mode=$mode'
      '&_sid=$sid';
}

/// 缩略图/原图直链：官方 `SYNO.FileStation.Thumb`，同样带 `_sid` 鉴权。
///
/// 图片预览用 `size=original`（返回原图），列表缩略图用 `size=small`。
String thumbUrl({
  required String baseUri,
  required String path,
  required String sid,
  int version = 2,
  String size = 'original',
}) {
  final base = baseUri.replaceFirst(RegExp(r'/+$'), '');
  return '$base/webapi/entry.cgi'
      '?api=SYNO.FileStation.Thumb'
      '&method=get'
      '&version=$version'
      '&path=${Uri.encodeComponent(path)}'
      '&size=$size'
      '&_sid=$sid'
      '&animate=true';
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

/// 歌曲封面直链：`SYNO.AudioStation.Cover`（Audio Station 自己存的封面/内嵌图）。
String audioCoverUrl({
  required String baseUri,
  required String id,
  required String sid,
  int version = 1,
  String size = 'medium',
}) {
  final base = baseUri.replaceFirst(RegExp(r'/+$'), '');
  return '$base/webapi/entry.cgi'
      '?api=SYNO.AudioStation.Cover'
      '&method=getcover'
      '&version=$version'
      '&id=${Uri.encodeComponent(id)}'
      '&size=$size'
      '&_sid=$sid';
}
