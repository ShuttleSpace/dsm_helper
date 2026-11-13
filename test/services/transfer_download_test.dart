import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/services/transfer_download.dart';
import 'package:garden/services/transfer_engine.dart';
import 'package:garden/stores/connection_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() {
    connectionStore.setSid('');
    connectionStore.setCookie('_SSID=abc');
    connectionStore.setSynoToken('TOK');
    connectionStore.setBaseUri('http://192.168.8.40:5000/');
  });

  test('buildDownloadTask wraps url/filename and attaches auth', () {
    final task = buildDownloadTask(
      url: 'http://192.168.8.40:5000/fbdownload/a.zip?dlink=x',
      directory: '/tmp/dl',
      filename: 'a.zip',
    );

    expect(task, isA<ParallelDownloadTask>());
    expect(task.url,
        'http://192.168.8.40:5000/fbdownload/a.zip?dlink=x');
    expect(task.filename, 'a.zip');
    // background_downloader 去掉首部路径分隔符；绝对路径用 root base 还原真实位置
    expect(task.directory, 'tmp/dl');
    expect(task.baseDirectory, BaseDirectory.root);
    expect(task.headers, authHeaders());
    expect(task.allowPause, isTrue);
  });

  test('relative directory maps to applicationDocuments base', () {
    final task = buildDownloadTask(
      url: 'http://h/f',
      directory: 'sub',
      filename: 'f',
    );
    expect(task.directory, 'sub');
    expect(task.baseDirectory, BaseDirectory.applicationDocuments);
  });

  test('buildDownloadTask falls back to downloadConcurrency for chunks', () {
    downloadConcurrency = 1;
    final task = buildDownloadTask(
      url: 'http://h/f',
      directory: '/d',
      filename: 'f',
    );
    expect(task.chunks, 1);
  });

  test('enqueueFileDownload derives /fbdownload url from remotePath', () {
    // URL 构造已在 transfer_url_test 覆盖；此处确认 builder 与 transfer_url 一致。
    final url = fbDownloadUrl(
      baseUri: connectionStore.baseUri.value,
      path: '/Download/a.zip',
      synoToken: connectionStore.synoToken.value,
    );
    final task = buildDownloadTask(
      url: url,
      directory: '/tmp',
      filename: 'a.zip',
    );
    expect(task.url, contains('/fbdownload/a.zip?dlink='));
    expect(task.url, contains('SynoToken=TOK'));
  });
}
