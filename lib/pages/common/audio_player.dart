import 'dart:async';
import 'dart:math';

import 'package:garden/models/player.dart';
import 'package:garden/stores/app_store.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:media_kit/media_kit.dart';

class AudioPlayer extends StatefulWidget {
  const AudioPlayer({
    super.key,
    required this.name,
    required this.url,
  });
  final String name;
  final String url;

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  late Player _player;
  String title = "";
  late StreamController<PlayerStateX> _stateController;
  late StreamSubscription<bool> _playingSubscription;
  late StreamSubscription<bool> _completedSubscription;
  late StreamSubscription<bool> _bufferSubscription;

  @override
  void initState() {
    _player = appStore.player ?? Player();
    appStore.setPlayer(_player);
    title = widget.name;

    // 初始化状态控制器
    _stateController = StreamController<PlayerStateX>.broadcast();

    // 监听播放状态
    _playingSubscription = _player.stream.playing.listen((isPlaying) {
      if (isPlaying) {
        _stateController.add(PlayerStateX.playing);
      } else {
        _stateController.add(PlayerStateX.paused);
      }
    });

    // 监听播放完成
    _completedSubscription = _player.stream.completed.listen((isCompleted) {
      if (isCompleted) {
        _stateController.add(PlayerStateX.completed);
      }
    });

    _bufferSubscription = _player.stream.buffering.listen((isBuffering) {
      if (isBuffering) {
        _stateController.add(PlayerStateX.buffering);
      }
    });

    // 设置音频源
    if (appStore.audioUrl != widget.url) {
      appStore.setAudioUrl(widget.url, title);
      _setSource();
    }

    super.initState();
  }

  @override
  void dispose() {
    _playingSubscription.cancel();
    _completedSubscription.cancel();
    _stateController.close();
    _bufferSubscription.cancel();
    super.dispose();
  }

  Future<void> _setSource() async {
    await _player.open(Media(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Center(
                    child: Image.asset(
                      "assets/music_cover.png",
                      width: 300,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(title),
              ],
            ),
            const SizedBox(height: 20),
            ControlButtons(
              player: _player,
              stateController: _stateController,
            ),
            SeekBar(
              player: _player,
              onChangeEnd: (newPosition) {
                _player.seek(newPosition);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final Player player;
  final StreamController<PlayerStateX> stateController;

  const ControlButtons({
    super.key,
    required this.player,
    required this.stateController,
  });

  void showSliderDialog({
    required BuildContext context,
    required String title,
    required int divisions,
    required double min,
    required double max,
    String valueSuffix = '',
    required double value,
    required Stream<double> stream,
    required ValueChanged<double> onChanged,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: StreamBuilder<double>(
          stream: stream,
          builder: (context, snapshot) => SizedBox(
            height: 100.0,
            child: Column(
              children: [
                Text(
                  '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                  style: const TextStyle(
                    fontFamily: 'Fixed',
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                Slider(
                  divisions: divisions,
                  min: min,
                  max: max,
                  value: snapshot.data ?? value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 音量按钮
        OutlinedButton(
          child: const Icon(Icons.volume_up),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "音量",
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: player.state.volume / 100,
              stream: player.stream.volume,
              onChanged: player.setVolume,
            );
          },
        ),

        const SizedBox(width: 30),

        // 播放/暂停按钮
        StreamBuilder<PlayerStateX>(
          stream: stateController.stream,
          builder: (context, snapshot) {
            if (snapshot.data == PlayerStateX.buffering) {
              return OutlinedButton(
                onPressed: player.play,
                child: const CupertinoActivityIndicator(radius: 24),
              );
            } else if (snapshot.data == PlayerStateX.stopped ||
                snapshot.data == PlayerStateX.paused) {
              return OutlinedButton(
                onPressed: player.play,
                child: const Icon(Icons.play_arrow, size: 64),
              );
            } else if (snapshot.data == PlayerStateX.playing) {
              return OutlinedButton(
                onPressed: player.pause,
                child: const Icon(Icons.pause, size: 64),
              );
            } else {
              // 播放完成，重新播放
              return OutlinedButton(
                child: const Icon(Icons.play_arrow, size: 64),
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),

        const SizedBox(width: 30),

        // 速度按钮
        StreamBuilder<double>(
          stream: player.stream.rate,
          builder: (context, snapshot) => OutlinedButton(
            child: Text(
              "${snapshot.data?.toStringAsFixed(1)}x",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "速度",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: player.state.rate,
                stream: player.stream.rate,
                onChanged: (value) {
                  player.setRate(value);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SeekBar extends StatefulWidget {
  final Player player;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    super.key,
    required this.player,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  SeekBarState createState() => SeekBarState();
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

class SeekBarState extends State<SeekBar> {
  double? _dragValue;
  SliderThemeData? _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 缓冲进度条（背景）
        SliderTheme(
          data: _sliderThemeData?.copyWith(
                thumbShape: HiddenThumbComponentShape(),
                activeTrackColor: Colors.blue.shade100,
                inactiveTrackColor: Colors.grey.shade300,
              ) ??
              const SliderThemeData(),
          child: ExcludeSemantics(
            child: StreamBuilder<Duration>(
              stream: widget.player.stream.buffer,
              builder: (context, snapshot) {
                final Duration duration = widget.player.state.duration;
                final Duration bufferedPosition =
                    snapshot.data ?? Duration.zero;
                return Slider(
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble(),
                  value: bufferedPosition.inMilliseconds.toDouble(),
                  onChanged: null, // 缓冲进度不可交互
                );
              },
            ),
          ),
        ),

        // 播放进度条（可交互）
        StreamBuilder<Duration>(
          stream: widget.player.stream.position,
          builder: (context, snapshot) {
            final Duration duration = widget.player.state.duration;
            final Duration position = snapshot.data ?? Duration.zero;
            final Duration remaining = duration - position;

            return Column(
              children: [
                Slider(
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble(),
                  value: min(
                    _dragValue ?? position.inMilliseconds.toDouble(),
                    duration.inMilliseconds.toDouble(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _dragValue = value;
                    });
                    widget.onChanged
                        ?.call(Duration(milliseconds: value.round()));
                  },
                  onChangeEnd: (value) {
                    widget.onChangeEnd
                        ?.call(Duration(milliseconds: value.round()));
                    _dragValue = null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          color: AppTheme.of(context).placeholderColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(remaining),
                        style: TextStyle(
                          color: AppTheme.of(context).placeholderColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
