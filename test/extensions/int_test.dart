import 'package:flutter_test/flutter_test.dart';
import 'package:garden/extensions/int.dart';

void main() {
  group('formatSize', () {
    test('works on int and double (static types)', () {
      expect(8192.formatSize(), '8.00K');
      expect((8192.0).formatSize(), '8.00K');
      expect(0.formatSize(), '0');
      expect(512.formatSize(), '512');
    });

    test('works on DSM dynamic values after cast to num', () {
      // DSM 返回的配额是 dynamic；扩展方法对 dynamic 调用点不生效，
      // 调用点必须先 as num。这里断言修复后的调用方式。
      dynamic quotaBytes = 8192.0;
      expect((quotaBytes as num).formatSize(), '8.00K');

      dynamic mb = 8;
      expect(((mb as num) * 1024 * 1024).formatSize(), '8.00M');
    });
  });
}
