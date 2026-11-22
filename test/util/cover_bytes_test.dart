import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:garden/util/cover_bytes.dart';

void main() {
  test('从 ID3 前缀里切出 JPEG 封面', () {
    final jpeg =
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 0xFF, 0xD9]);
    final bytes = Uint8List.fromList([
      ...'ID3'.codeUnits,
      ...List.filled(40, 0),
      ...jpeg,
      ...List.filled(40, 0),
    ]);
    expect(extractCoverImage(bytes), jpeg);
  });

  test('PNG 封面按 IEND 收尾', () {
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 9, 9, //
      0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    final bytes = Uint8List.fromList([...List.filled(20, 0), ...png]);
    expect(extractCoverImage(bytes), png);
  });

  test('没有图就返回 null', () {
    expect(extractCoverImage(Uint8List.fromList(List.filled(64, 7))), isNull);
    expect(extractCoverImage(Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3])),
        isNull);
  });
}
