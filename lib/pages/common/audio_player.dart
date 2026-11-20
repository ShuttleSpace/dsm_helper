import 'dart:async';
import 'dart:math';

import 'package:garden/models/player.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:media_kit/media_kit.dart';
import 'package:signals_hooks/signals_hooks.dart';

class AudioPlayer extends HookWidget {
  const AudioPlayer({
    super.key,
    required this.name,
    required this.url,
  });
  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    final player =
        useMemoized(() => settingsStore.player.value ?? Player(), const []);
    final stateController = useMemoized(
        () => StreamController<PlayerStateX>.broadcast(), const []);

    Future<void> setSource() async {
      await player.open(Media(url));
    }

    useEffect(() {
      settingsStore.setPlayer(player);

      // 监听播放状态
      final playingSubscription = player.stream.playing.listen((isPlaying) {
        if (isPlaying) {
          stateController.add(PlayerStateX.playing);
        } else {
          stateController.add(PlayerStateX.paused);
        }
      });

      // 监听播放完成
      final completedSubscription =
          player.stream.completed.listen((isCompleted) {
        if (isCompleted) {
          stateController.add(PlayerStateX.completed);
        }
      });

      final bufferSubscription =
          player.stream.buffering.listen((isBuffering) {
        if (isBuffering) {
          stateController.add(PlayerStateX.buffering);
        }
      });

      // 设置音频源
      if (settingsStore.audioUrl.value != url) {
        settingsStore.setAudioUrl(url, name);
        setSource();
      }

      return () {
        playingSubscription.cancel();
        completedSubscription.cancel();
        stateController.close();
        bufferSubscription.cancel();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(name),
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
                Text(name),
              ],
            ),
            const SizedBox(height: 20),
            ControlButtons(
              player: player,
              stateController: stateController,
            ),
            SeekBar(
              player: player,
              onChangeEnd: (newPosition) {
                player.seek(newPosition);
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

class SeekBar extends HookWidget {
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
  Widget build(BuildContext context) {
    final dragValue = useSignal<double?>(null);
    final sliderThemeData =
        SliderTheme.of(context).copyWith(trackHeight: 2.0);

    String formatDuration(Duration duration) {
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

    return Stack(
      children: [
        // 缓冲进度条（背景）
        SliderTheme(
          data: sliderThemeData.copyWith(
            thumbShape: HiddenThumbComponentShape(),
            activeTrackColor: Colors.blue.shade100,
            inactiveTrackColor: Colors.grey.shade300,
          ),
          child: ExcludeSemantics(
            child: StreamBuilder<Duration>(
              stream: player.stream.buffer,
              builder: (context, snapshot) {
                final Duration duration = player.state.duration;
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
          stream: player.stream.position,
          builder: (context, snapshot) {
            final Duration duration = player.state.duration;
            final Duration position = snapshot.data ?? Duration.zero;
            final Duration remaining = duration - position;

            return Column(
              children: [
                Slider(
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble(),
                  value: min(
                    dragValue.value ?? position.inMilliseconds.toDouble(),
                    duration.inMilliseconds.toDouble(),
                  ),
                  onChanged: (value) {
                    dragValue.value = value;
                    onChanged?.call(Duration(milliseconds: value.round()));
                  },
                  onChangeEnd: (value) {
                    onChangeEnd?.call(Duration(milliseconds: value.round()));
                    dragValue.value = null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(position),
                        style: TextStyle(
                          color: AppTheme.of(context).placeholderColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatDuration(remaining),
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
