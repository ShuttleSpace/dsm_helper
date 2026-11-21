import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/tmdb_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:garden/widgets/settings/settings_checkbox_tile.dart';

/// 可选字幕字号（逻辑像素）
const List<int> subtitleFontSizes = [12, 14, 16, 18, 20, 24, 28, 32];

/// 视频播放相关设置：第三方播放器开关 + 字幕字号 + TMDB 刮削用的 API Key。
class PlayerSettingPage extends HookWidget {
  const PlayerSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final showKey = useState(false);
    final externalPlayer = useState(true);
    final subtitleSize = useState(16);

    useEffect(() {
      StorageUtil.getString(tmdbApiKeyStorageKey).then((value) {
        if (value != null) controller.text = value;
      });
      // 与 lib/pages/file/file.dart 的取值默认值保持一致
      StorageUtil.getBool("use_embeed_video_player").then((value) {
        externalPlayer.value = value ?? true;
      });
      StorageUtil.getInt("subtitle_font_size").then((value) {
        if (value != null) subtitleSize.value = value;
      });
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
          const SizedBox(height: 20),
          const Text("TMDB API Key"),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      obscureText: !showKey.value,
                      decoration: const InputDecoration(
                        hintText: "留空则不刮削",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => showKey.value = !showKey.value,
                    icon: Icon(showKey.value
                        ? Icons.visibility_off
                        : Icons.visibility),
                  ),
                  TextButton(
                    onPressed: () async {
                      await StorageUtil.setString(
                          tmdbApiKeyStorageKey, controller.text.trim());
                      UiUtil.toast("已保存");
                    },
                    child: const Text("保存"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "本地没有 NFO 文件时，用文件名去 TMDB 查简介、类型、评分等信息。"
            "Key 免费申请：themoviedb.org/settings/api\n"
            "本产品使用 TMDB API，但未获得 TMDB 认可或认证。",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
