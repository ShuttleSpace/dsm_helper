import 'package:flutter_test/flutter_test.dart';
import 'package:garden/stores/connection_store.dart';

void main() {
  test('connection store signals read/write', () {
    connectionStore.setSid('abc');
    expect(connectionStore.sid.value, 'abc');
    connectionStore.setBaseUri('http://1.2.3.4:5000/');
    expect(connectionStore.baseUri.value, 'http://1.2.3.4:5000/');
    connectionStore.setAccount('humphrey');
    expect(connectionStore.account.value, 'humphrey');
  });
}
