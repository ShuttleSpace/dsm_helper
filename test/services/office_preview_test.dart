import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  test('fileContentUrl 带 dlink 与 _sid，且 mode=open', () {
    final url = fileContentUrl({'name': 'a b.docx', 'path': '/Download/a b.docx'});
    expect(url, startsWith('http://192.168.8.40:5000/fbdownload/a%20b.docx'));
    expect(url, contains('dlink=%22'));
    expect(url, contains('_sid=%22SID123%22'));
    expect(url, contains('mode=open'));
  });
}
