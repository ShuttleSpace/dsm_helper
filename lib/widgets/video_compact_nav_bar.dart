import 'package:flutter/material.dart';

/// 窄播放区里「上一个 / 下一个 / 播放列表」平分剩余宽度。
///
/// 竖屏 9:16 视频在 360x800 屏上播放区只有 135px，media_kit 的底部条还要扣掉
/// 左 16 / 右 8 外边距和全屏键，固定宽度的按钮必然 RenderFlex overflowed；
/// 这里用 Expanded 平分、图标按 [iconSize] 一起缩小，宽度不够时只是按钮变窄。
class VideoCompactNavBar extends StatelessWidget {
  const VideoCompactNavBar({
    super.key,
    required this.iconSize,
    this.onPrevious,
    this.onNext,
    this.onPlaylist,
  });

  final double iconSize;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPlaylist;

  Widget _button(IconData icon, String tooltip, VoidCallback? onTap) => Expanded(
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: iconSize),
          style: IconButton.styleFrom(backgroundColor: Colors.black38),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          visualDensity: VisualDensity.compact,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _button(Icons.skip_previous, '上一个', onPrevious),
        _button(Icons.skip_next, '下一个', onNext),
        if (onPlaylist != null) _button(Icons.playlist_play, '播放列表', onPlaylist),
      ],
    );
  }
}
