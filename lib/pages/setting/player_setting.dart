import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:garden/widgets/settings/settings_checkbox_tile.dart';

/// 可选字幕字号（逻辑像素）
const List<int> subtitleFontSizes = [12, 14, 16, 18, 20, 24, 28, 32];

/// 播放器设置：第三方播放器开关 + 字幕字号（TMDB 的 Key 在多媒体设置里）。
class PlayerSettingPage extends HookWidget {
  const PlayerSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final externalPlayer = useState(true);
    final subtitleSize = useState(16);
    final autoNext = useState(true);

    useEffect(() {
      // 与 lib/pages/file/file.dart 的取值默认值保持一致
      StorageUtil.getBool("use_embeed_video_player").then((value) {
        externalPlayer.value = value ?? false;
      });
      StorageUtil.getInt("subtitle_font_size").then((value) {
        if (value != null) subtitleSize.value = value;
      });
      StorageUtil.getBool("auto_play_next")
          .then((value) => autoNext.value = value ?? true);
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text('播放器设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SettingsCheckboxTile(
            label: "优先使用第三方播放器",
            value: externalPlayer.value,
            iconAsset: "assets/icons/player.png",
            iconWidth: 25,
            padding: 20,
            onTap: () {
              externalPlayer.value = !externalPlayer.value;
              StorageUtil.setBool(
                  "use_embeed_video_player", externalPlayer.value);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 8),
            child: Text(
              "仅 Android 生效：打开视频时交给系统里能播的 App；关掉用内置播放器。",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          SettingsCheckboxTile(
            label: "自动连播下一集",
            value: autoNext.value,
            iconAsset: "assets/icons/movie.png",
            iconWidth: 25,
            padding: 20,
            onTap: () {
              autoNext.value = !autoNext.value;
              StorageUtil.setBool("auto_play_next", autoNext.value);
            },
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => showCupertinoModalPopup(
              context: context,
              builder: (context) => Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
                child: NeuPicker(
                  [for (final size in subtitleFontSizes) "$size"],
                  value: subtitleFontSizes.indexOf(subtitleSize.value),
                  onConfirm: (index) {
                    subtitleSize.value = subtitleFontSizes[index];
                    StorageUtil.setInt(
                        "subtitle_font_size", subtitleSize.value);
                  },
                ),
              ),
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text("字幕字号"),
                    const Spacer(),
                    Text("${subtitleSize.value}"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
