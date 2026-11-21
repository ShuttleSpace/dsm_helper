import 'package:flutter_test/flutter_test.dart';
import 'package:garden/util/tmdb_util.dart';

void main() {
  group('guessTitleFromFileName', () {
    test('点号分隔 + 年份 + 画质后缀', () {
      final r = guessTitleFromFileName('The.Matrix.1999.1080p.BluRay.x264.mkv');
      expect(r.title, 'The Matrix');
      expect(r.year, '1999');
    });

    test('中文片名 + 年份', () {
      final r = guessTitleFromFileName('流浪地球2.2023.2160p.WEB-DL.mkv');
      expect(r.title, '流浪地球2');
      expect(r.year, '2023');
    });

    test('方括号与下划线', () {
      final r = guessTitleFromFileName('Interstellar_(2014)_[1080p].mp4');
      expect(r.title, 'Interstellar');
      expect(r.year, '2014');
    });

    test('片名本身是年份时不截断', () {
      final r = guessTitleFromFileName('1917.mkv');
      expect(r.title, '1917');
      expect(r.year, '');
    });

    test('没有年份', () {
      final r = guessTitleFromFileName('some random vlog.mp4');
      expect(r.title, 'some random vlog');
      expect(r.year, '');
    });
  });

  test('pickSearchHit 优先年份匹配，忽略 person 结果', () {
    final json = {
      'results': [
        {'media_type': 'person', 'id': 1},
        {'media_type': 'movie', 'id': 603, 'release_date': '1999-03-31'},
        {'media_type': 'movie', 'id': 604, 'release_date': '2003-05-15'},
      ],
    };
    expect(pickSearchHit(json, '2003'), (id: 604, mediaType: 'movie'));
    expect(pickSearchHit(json, '1999'), (id: 603, mediaType: 'movie'));
    // 年份对不上时退回第一条 movie/tv
    expect(pickSearchHit(json, '2020'), (id: 603, mediaType: 'movie'));
    expect(pickSearchHit({'results': []}, '1999'), isNull);
    expect(pickSearchHit(null, '1999'), isNull);
  });

  test('parseTmdbDetail 映射 movie 字段', () {
    final info = parseTmdbDetail({
      'title': '黑客帝国',
      'overview': '一个 hacker 的故事',
      'release_date': '1999-03-31',
      'runtime': 136,
      'vote_average': 8.2,
      'poster_path': '/abc.jpg',
      'genres': [
        {'id': 28, 'name': '动作'},
        {'id': 878, 'name': '科幻'},
      ],
    }, 'movie');
    expect(info!.title, '黑客帝国');
    expect(info.year, '1999');
    expect(info.premiered, '1999-03-31');
    expect(info.genres, '动作、科幻');
    expect(info.runtime, '136');
    expect(info.rating, '8.2');
    expect(info.poster, 'https://image.tmdb.org/t/p/w500/abc.jpg');
  });

  test('parseTmdbDetail 处理 tv 与缺失字段', () {
    final tv = parseTmdbDetail({
      'name': '某剧',
      'first_air_date': '2021-01-02',
      'episode_run_time': [45],
      'genres': [
        {'id': 18, 'name': '剧情'}
      ],
    }, 'tv');
    expect(tv!.year, '2021');
    expect(tv.runtime, '45');
    expect(tv.poster, '');
    expect(tv.rating, '');

    expect(parseTmdbDetail(null, 'movie'), isNull);
    expect(parseTmdbDetail({}, 'movie')!.year, '');
  });

  test('TmdbInfo JSON 往返不丢字段', () {
    const info = TmdbInfo(
      title: '片名',
      overview: '简介',
      year: '2023',
      genres: '科幻',
      runtime: '120',
      rating: '8.1',
      premiered: '2023-01-01',
      poster: 'https://image.tmdb.org/t/p/w500/a.jpg',
    );
    final back = TmdbInfo.fromJson(info.toJson());
    expect(back.toJson(), info.toJson());
  });
}
