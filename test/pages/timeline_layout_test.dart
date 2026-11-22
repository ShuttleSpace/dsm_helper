import 'package:flutter_test/flutter_test.dart';
import 'package:garden/models/photos/timeline_model.dart';
import 'package:garden/pages/photos/timeline.dart';

void main() {
  test('每行 4 张算行数，高度和起始位置按天数累加', () {
    final days = layoutTimelineDays([
      TimelineModel(days: [
        Day(day: 2, month: 11, year: 2026, itemCount: 4), // 1 行
        Day(day: 1, month: 11, year: 2026, itemCount: 5), // 2 行
        Day(day: 31, month: 10, year: 2026, itemCount: 0), // 0 行
      ])
    ], 100);

    expect(days.length, 3);
    expect(days[0].startPosition, 0);
    expect(days[0].endPosition, 40 + 1 * 100);
    expect(days[1].startPosition, days[0].endPosition);
    expect(days[1].endPosition, (40 + 1 * 100) + (40 + 2 * 100 + 2));
    expect(days[2].endPosition, (40 + 1 * 100) + (40 + 2 * 100 + 2) + (40 - 2));
  });
}
