import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/stores/connection_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() {
    connectionStore.setSid('SID123');
    connectionStore.setBaseUri('http://192.168.8.40:5000/');
  });

  test('只有 docx/xlsx/xls 走内嵌 JS 预览', () {
    expect(canWebPreview('a.docx'), isTrue);
    expect(canWebPreview('A.XLSX'), isTrue);
    expect(canWebPreview('b.xls'), isTrue);
    expect(canWebPreview('b.doc'), isFalse);
    expect(canWebPreview('b.pptx'), isFalse);
    expect(canWebPreview('b.iso'), isFalse);
    expect(canWebPreview('b.torrent'), isFalse);
  });

  test('fileExtension 取小写后缀，无后缀返回空', () {
    expect(fileExtension('a.DOCX'), 'docx');
    expect(fileExtension('README'), '');
  });

  test('fileContentUrl 经新层构造官方下载直链（带 _sid、mode=open）', () {
    final url = fileContentUrl({'name': 'a b.docx', 'path': '/Download/a b.docx'});
    expect(url, startsWith('http://192.168.8.40:5000/webapi/entry.cgi'));
    expect(url, contains('api=SYNO.FileStation.Download'));
    expect(url, contains('path=%2FDownload%2Fa%20b.docx'));
    expect(url, contains('_sid=SID123'));
    expect(url, contains('mode=open'));
    expect(url, isNot(contains('/fbdownload/')));
  });

  test('fbDownloadUrl 默认 mode=download，可显式 mode=open 供预览内联', () {
    const baseUri = 'http://192.168.8.40:5000/';
    const path = '/Download/a.docx';
    const sid = 'SID123';
    final download =
        fbDownloadUrl(baseUri: baseUri, path: path, sid: sid);
    final inline =
        fbDownloadUrl(baseUri: baseUri, path: path, sid: sid, mode: 'open');
    expect(download, contains('mode=download'));
    expect(inline, contains('mode=open'));
    expect(inline, contains('_sid=SID123'));
    expect(inline, contains('path=%2FDownload%2Fa.docx'));
  });

  test('thumbUrl 构造鉴权缩略图直链（含 size 与 _sid）', () {
    final url = thumbUrl(
      baseUri: 'http://192.168.8.40:5000/',
      path: '/Download/a.jpg',
      sid: 'SID123',
      size: 'small',
    );
    expect(url, startsWith('http://192.168.8.40:5000/webapi/entry.cgi'));
    expect(url, contains('api=SYNO.FileStation.Thumb'));
    expect(url, contains('path=%2FDownload%2Fa.jpg'));
    expect(url, contains('size=small'));
    expect(url, contains('_sid=SID123'));
  });

  test('dsmErrorMapFromBytes 从错误信封取出 DSM 错误，正常文件字节返回 null', () {
    final errorBytes = utf8.encode(
        '{"success":false,"error":{"code":119,"key":"invalid_session"}}');
    final map = dsmErrorMapFromBytes(errorBytes);
    expect(map, isNotNull);
    expect(map!['error']['code'], 119);

    expect(dsmErrorMapFromBytes(utf8.encode('{"success":true}')), isNull);
    expect(dsmErrorMapFromBytes(<int>[0, 1, 2, 3]), isNull);
    expect(dsmErrorMapFromBytes(<int>[]), isNull);
  });
}
