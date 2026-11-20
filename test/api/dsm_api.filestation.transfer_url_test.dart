import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';

void main() {
  test('fbDownloadUrl uses official FileStation.Download with sid and encoded path',
      () {
    const baseUri = 'http://192.168.8.40:5000/';
    const path = '/Download/a b.zip';
    final url = fbDownloadUrl(baseUri: baseUri, path: path, sid: 'SID');

    expect(url, startsWith('http://192.168.8.40:5000/webapi/entry.cgi?'));
    expect(url, contains('api=SYNO.FileStation.Download'));
    expect(url, contains('method=download'));
    expect(url, contains('version=2'));
    expect(url, contains('path=${Uri.encodeComponent(path)}'));
    expect(url, contains('mode=download'));
    expect(url, contains('_sid=SID'));
    expect(url, isNot(contains('fbdownload')));
  });

  test('fbDownloadUrl tolerates a trailing slash on baseUri', () {
    final url = fbDownloadUrl(
        baseUri: 'http://h:5000', path: '/x', sid: 'S');
    expect(url, startsWith('http://h:5000/webapi/entry.cgi?'));
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
