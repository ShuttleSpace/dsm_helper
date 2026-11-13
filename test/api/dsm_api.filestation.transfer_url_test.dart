import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';

void main() {
  test('dsmBase64Path encodes the raw path without URL escaping', () {
    const path = '/Download/中文/a.zip';
    expect(dsmBase64Path(path), base64.encode(utf8.encode(path)));
  });

  test('fbDownloadUrl builds /fbdownload URL with base64 dlink and token', () {
    const baseUri = 'http://192.168.8.40:5000/';
    const path = '/Download/a.zip';
    const token = 'TOK';
    final url = fbDownloadUrl(baseUri: baseUri, path: path, synoToken: token);

    expect(url, startsWith('http://192.168.8.40:5000/fbdownload/a.zip?dlink='));
    expect(url, contains('dlink=${dsmBase64Path(path)}'));
    expect(url, contains('mode=download'));
    expect(url, contains('SynoToken=$token'));
  });

  test('uploadEntryUrl embeds api, version and token', () {
    const baseUri = 'http://192.168.8.40:5000/';
    final url = uploadEntryUrl(
        baseUri: baseUri, synoToken: 'TOK', version: 3);

    expect(url, contains('webapi/entry.cgi'));
    expect(url, contains('api=SYNO.FileStation.Upload'));
    expect(url, contains('version=3'));
    expect(url, contains('SynoToken=TOK'));
  });

  test('uploadEntryUrl version defaults to 2', () {
    final url = uploadEntryUrl(baseUri: 'http://h:5000/', synoToken: 'T');
    expect(url, contains('version=2'));
  });
}
