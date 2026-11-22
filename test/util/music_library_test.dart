import 'package:flutter_test/flutter_test.dart';
import 'package:garden/util/music_library.dart';

void main() {
  test('解析歌曲：标签取 song_tag，时长取 song_audio，没标题回退文件名', () {
    final songs = parseMusicSongs({
      'songs': [
        {
          'id': 'song_1',
          'path': '/music/周杰伦/稻香.flac',
          'additional': {
            'song_tag': {'artist': '周杰伦', 'album': '魔杰座'},
            'song_audio': {'duration': 223},
          },
        },
        {
          'id': 'song_2',
          'path': '/music/无名/没标签.mp3',
        },
        {'id': 'song_3'},
      ]
    }, const []);

    expect(songs.length, 2); // 没 path 的丢掉
    expect(songs.first.title, '稻香'); // 没 title 时用文件名
    expect(songs.first.artist, '周杰伦');
    expect(songs.first.album, '魔杰座');
    expect(songs.first.seconds, 223);
    expect(songs.first.subtitleLine, '周杰伦 · 魔杰座');
    expect(songs[1].title, '没标签');
    expect(songs[1].subtitleLine, '');
  });

  test('目录过滤：配了目录就只留目录下的', () {
    final data = {
      'songs': [
        {'id': 'a', 'path': '/music/rock/a.mp3'},
        {'id': 'b', 'path': '/music/jazz/b.mp3'},
      ]
    };
    expect(parseMusicSongs(data, const []).length, 2);
    expect(parseMusicSongs(data, const ['/music/jazz']).single.id, 'b');
    expect(parseMusicSongs(data, const ['/nope']), isEmpty);
  });

  test('排序：歌名 / 艺人 / 专辑', () {
    const songs = [
      MusicSong(id: '1', path: '/b', title: 'b', artist: 'Z', album: 'x'),
      MusicSong(id: '2', path: '/a', title: 'a', artist: 'A', album: 'z'),
    ];
    expect([for (final e in sortMusicSongs(songs, MusicSort.title)) e.title],
        ['a', 'b']);
    expect(sortMusicSongs(songs, MusicSort.artist).first.artist, 'A');
    expect(sortMusicSongs(songs, MusicSort.album).first.album, 'x');
  });

  test('时长文案', () {
    expect(formatSongDuration(const Duration(seconds: 7)), '0:07');
    expect(formatSongDuration(const Duration(minutes: 3, seconds: 7)), '3:07');
    expect(formatSongDuration(const Duration(hours: 1, seconds: 5)), '1:00:05');
  });
}
