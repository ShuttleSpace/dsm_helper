import 'package:flutter_test/flutter_test.dart';
import 'package:garden/pages/common/video_player.dart';

void main() {
  test('joinNfoNames 兼容字符串 / 数组 / 带属性的对象数组', () {
    expect(joinNfoNames(null), '');
    expect(joinNfoNames('动作'), '动作');
    expect(joinNfoNames(['动作', '科幻']), '动作、科幻');
    expect(
        joinNfoNames([
          {'name': '诺兰'}
        ]),
        '诺兰');
    expect(
        joinNfoNames([
          {r'$': '张三'},
          '李四'
        ]),
        '张三、李四');
  });

  test('firstNfoImage 只取远程图，忽略本地文件名', () {
    expect(firstNfoImage(null), '');
    expect(firstNfoImage('poster.jpg'), '');
    expect(firstNfoImage('https://image.tmdb.org/a.jpg'),
        'https://image.tmdb.org/a.jpg');
    expect(
        firstNfoImage([
          {'aspect': 'poster', r'$': 'https://x/p.jpg'}
        ]),
        'https://x/p.jpg');
    expect(
      firstNfoImage([
        'poster.jpg',
        {'aspect': 'fanart', r'$': 'https://x/f.jpg'}
      ]),
      'https://x/f.jpg',
    );
  });
}
