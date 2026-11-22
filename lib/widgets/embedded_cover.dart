import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:garden/util/cover_bytes.dart';
import 'package:garden/util/music_library.dart';

/// 歌曲内嵌封面；没有就显示音符占位。
class EmbeddedCover extends StatelessWidget {
  const EmbeddedCover({
    super.key,
    required this.song,
    required this.size,
    this.radius = 6,
  });

  final MusicSong song;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: FutureBuilder<Uint8List?>(
          future: loadEmbeddedCover(song),
          builder: (context, snapshot) => snapshot.data == null
              ? Container(
                  width: size,
                  height: size,
                  color: Colors.black12,
                  child: Icon(Icons.music_note,
                      size: size * 0.5, color: Colors.grey),
                )
              : Image.memory(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  cacheWidth: (size * 3).toInt(),
                  errorBuilder: (context, error, stack) => Container(
                    width: size,
                    height: size,
                    color: Colors.black12,
                    child: Icon(Icons.music_note,
                        size: size * 0.5, color: Colors.grey),
                  ),
                ),
        ),
      );
}
