import 'package:flutter_test/flutter_test.dart';
import 'package:garden/util/file_type_util.dart';

void main() {
  test('findSiblingSubtitles 只收同名 + 字幕扩展名', () {
    final files = [
      {'name': 'Movie.2024.mkv', 'path': '/v/Movie.2024.mkv'},
      {'name': 'Movie.2024.srt', 'path': '/v/Movie.2024.srt'},
      {'name': 'Movie.2024.zh.ass', 'path': '/v/Movie.2024.zh.ass'},
      {'name': 'Movie.2024.txt', 'path': '/v/Movie.2024.txt'},
      {'name': 'Movie.2024x.srt', 'path': '/v/Movie.2024x.srt'},
      {'name': 'Other.mkv', 'path': '/v/Other.mkv'},
    ];
    expect(
      FileTypeUtil.findSiblingSubtitles(files, 'Movie.2024'),
      ['/v/Movie.2024.srt', '/v/Movie.2024.zh.ass'],
    );
  });

  test('findSiblingSubtitles 无字幕时返回空', () {
    final files = [
      {'name': 'a.mp4', 'path': '/v/a.mp4'},
      {'name': 'b.srt', 'path': '/v/b.srt'},
    ];
    expect(FileTypeUtil.findSiblingSubtitles(files, 'a'), isEmpty);
  });
}
