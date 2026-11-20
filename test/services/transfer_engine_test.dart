import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garden/services/transfer_engine.dart';
import 'package:garden/stores/connection_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    connectionStore.setSid('');
    connectionStore.setCookie('');
    connectionStore.setSynoToken('');
  });

  test('authHeaders returns empty map when no session cookie or token', () {
    expect(authHeaders(), isEmpty);
  });

  test('authHeaders includes Cookie and X-SYNO-TOKEN when set', () {
    connectionStore.setCookie('_SSID=abc; id=x');
    connectionStore.setSynoToken('TOK');

    expect(authHeaders(), {
      'Cookie': '_SSID=abc; id=x',
      'X-SYNO-TOKEN': 'TOK',
    });
  });

  test('authHeaders omits a header whose value is empty', () {
    connectionStore.setCookie('_SSID=abc');

    expect(authHeaders(), {'Cookie': '_SSID=abc'});
  });
}
