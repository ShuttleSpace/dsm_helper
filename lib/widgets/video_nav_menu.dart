import 'package:flutter/material.dart';

/// 窄播放区放不下「上一个 / 下一个 / 播放列表」三个按钮时，把它们收进一个菜单，
/// 否则底部控制条会 RenderFlex overflowed。
class VideoNavMenu extends StatelessWidget {
  const VideoNavMenu({
    super.key,
    this.onPrevious,
    this.onNext,
    this.onPlaylist,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPlaylist;

  bool get isEmpty => onPrevious == null && onNext == null && onPlaylist == null;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: '更多',
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      itemBuilder: (context) => [
        if (onPrevious != null)
          const PopupMenuItem(value: 0, child: Text('上一个')),
        if (onNext != null) const PopupMenuItem(value: 1, child: Text('下一个')),
        if (onPlaylist != null)
          const PopupMenuItem(value: 2, child: Text('播放列表')),
      ],
      onSelected: (value) {
        switch (value) {
          case 0:
            onPrevious?.call();
          case 1:
            onNext?.call();
          case 2:
            onPlaylist?.call();
        }
      },
    );
  }
}
