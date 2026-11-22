import 'package:garden/pages/photos/photos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 顶部下拉框必须放得下「图片/相册/共享」两个汉字，否则文字被截断。
void main() {
  for (final width in [320.0, 360.0, 430.0]) {
    testWidgets('photos topbar dropdown label fits at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: const SizedBox(width: 56),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('个人空间'),
                ),
              ),
            ],
            title: Builder(
              builder: (context) => buildPhotosMenu(context, 1, (_) {}),
            ),
          ),
        ),
      ));

      final editable =
          tester.renderObject<RenderBox>(find.byType(EditableText).first);
      final painter = TextPainter(
        text: const TextSpan(text: '相册', style: TextStyle(fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();

      expect(tester.takeException(), isNull);
      expect(editable.size.width, greaterThanOrEqualTo(painter.width),
          reason: '文字可用宽度 ${editable.size.width} 小于两个字所需 ${painter.width}');
    });
  }
}
