import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/pages/setting/media_library_setting.dart';
import 'package:garden/util/media_library.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/tmdb_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:garden/widgets/settings/settings_checkbox_tile.dart';

/// 扫描深度可选项，库目录自身算第 0 层。
const List<int> mediaScanDepthOptions = [1, 2, 3, 4, 5];

/// 多媒体自己的设置：库目录、扫描深度、TMDB 补封面、NFO 缓存。
class MediaSetting extends HookWidget {
  const MediaSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final showKey = useState(false);
    final depth = useState(mediaScanDepth);
    final tmdbPoster = useState(true);
    final pathCount = useState(0);

    Future<void> refreshCount() async {
      pathCount.value = (await loadMediaLibraryPaths()).length;
    }

    useEffect(() {
      StorageUtil.getString(tmdbApiKeyStorageKey).then((value) {
        if (value != null) controller.text = value;
      });
      loadMediaScanDepth().then((value) => depth.value = value);
      loadMediaUseTmdbPoster().then((value) => tmdbPoster.value = value);
      refreshCount();
      return null;
    }, const []);

    Widget card({required Widget child}) => Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(),
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        );

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        );

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text('多媒体设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => const MediaLibrarySetting()));
              await refreshCount();
            },
            child: card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text("媒体库目录"),
                    const Spacer(),
                    Text("${pathCount.value} 个",
                        style: const TextStyle(color: Colors.grey)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 8),
            child: Text(
              "多媒体页只扫这些 NAS 目录下的视频，同目录的封面、NFO、字幕会一起带出来。",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          label("扫描深度"),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showCupertinoModalPopup(
              context: context,
              builder: (context) => Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
                child: NeuPicker(
                  [for (final d in mediaScanDepthOptions) "$d 层"],
                  value: mediaScanDepthOptions.indexOf(depth.value),
                  onConfirm: (index) {
                    depth.value = mediaScanDepthOptions[index];
                    StorageUtil.setInt(mediaScanDepthStorageKey, depth.value);
                  },
                ),
              ),
            ),
            child: card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text("扫到第几层子目录"),
                    const Spacer(),
                    Text("${depth.value} 层"),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SettingsCheckboxTile(
            label: "没封面时用 TMDB 海报",
            value: tmdbPoster.value,
            iconAsset: "assets/icons/movie.png",
            iconWidth: 25,
            padding: 20,
            onTap: () {
              tmdbPoster.value = !tmdbPoster.value;
              StorageUtil.setBool(
                  mediaUseTmdbPosterStorageKey, tmdbPoster.value);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 8),
            child: Text(
              "按文件名去 TMDB 查一次海报并缓存 30 天，下面的 Key 留空就不查。",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          label("TMDB API Key"),
          const SizedBox(height: 8),
          card(
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
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 8),
            child: Text(
              "播放页缺简介/评分时也用它；Key 免费申请：themoviedb.org/settings/api\n"
              "本产品使用 TMDB API，但未获得 TMDB 认可或认证。",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final count = await clearNfoCache();
              UiUtil.toast(count == 0 ? "缓存是空的" : "已清掉 $count 条缓存");
            },
            child: card(
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text("清除 NFO 缓存"),
                    Spacer(),
                    Text("改过 NFO 后清一下",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
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
