import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  test('DSMException.fromMap preserves nested error payload', () {
    final res = {
      'success': false,
      'error': {
        'code': 117,
        'errors': {'runningTasks': [{'name': 't'}]}
      }
    };
    final e = DSMException.fromMap(res);
    expect(e.code, 117);
    expect(e.rawError, isA<Map>());
    expect((e.rawError!['errors'] as Map)['runningTasks'], isNotNull);
  });

  test('DSMException.fromMap preserves the whole response', () {
    final res = {
      'success': false,
      'error': {'code': 100, 'errors': ['x']}
    };
    final e = DSMException.fromMap(res);
    expect(e.rawResponse, isA<Map>());
    expect(e.rawResponse!['success'], false);
  });

  test('DSMException.fromMap without error leaves rawError null', () {
    final e = DSMException.fromMap({'success': false});
    expect(e.code, -1);
    expect(e.rawError, isNull);
    expect(e.rawResponse, isA<Map>());
  });

  test('existing message/code/description and toString do not regress', () {
    final e = DSMException.fromMap({'error': {'code': 101}});
    expect(e.code, 101);
    expect(e.message, 'Invalid parameter');
    expect(e.descriptionOrSolution, 'Check parameter value');
    expect(e.toString(), contains('code: 101'));
  });
}
