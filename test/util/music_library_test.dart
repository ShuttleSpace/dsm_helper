import 'package:flutter_test/flutter_test.dart';
import 'package:garden/util/music_library.dart';
import 'package:garden/util/music_player_controller.dart';

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

  group('放完之后转到哪首', () {
    test('顺序播放到最后一首就停', () {
      expect(indexAfterComplete(0, 3, MusicPlayMode.sequential), 1);
      expect(indexAfterComplete(2, 3, MusicPlayMode.sequential), isNull);
    });

    test('列表循环回到第一首', () {
      expect(indexAfterComplete(2, 3, MusicPlayMode.loop), 0);
    });

    test('单曲播放停下，单曲循环留在原地', () {
      expect(indexAfterComplete(1, 3, MusicPlayMode.single), isNull);
      expect(indexAfterComplete(1, 3, MusicPlayMode.singleLoop), 1);
    });

    test('空列表不炸', () {
      expect(indexAfterComplete(0, 0, MusicPlayMode.loop), isNull);
    });
  });

  test('快照 JSON 往返不丢字段', () {
    const song = MusicSong(
        id: 'music_1',
        path: '/m/a.mp3',
        title: '歌',
        artist: '人',
        album: '集',
        seconds: 211);
    final back = MusicSong.fromJson(song.toJson());
    expect(back.id, song.id);
    expect(back.path, song.path);
    expect(back.title, song.title);
    expect(back.artist, song.artist);
    expect(back.album, song.album);
    expect(back.seconds, song.seconds);
  });
}
