import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Update extends HookWidget {
  final Map data;
  final bool direct;
  const Update(this.data, {super.key, this.direct = false});

  @override
  Widget build(BuildContext context) {
    final downloading = useSignal(false);
    final progress = useSignal(0.0);

    download() async {
      // 检查安装应用权限
      // if (!await Permission.requestInstallPackages.request().isGranted) {
      //   HttpUtil.toast("权限不足，无法安装更新");
      // }
      downloading.value = true;
      try {
        // TODO: 使用替代方案下载和安装 APK
        // 暂时使用浏览器下载
        await launchUrlString(data['downloadURL']);
        downloading.value = false;
        // /// 仅支持将APK下载到沙盒目录下
        // /// 当前这个示例最终生成的文件路径就是 '/data/user/0/$applicationPackageName/files/updateApk/new.apk'
        // /// 如果连续调用此方法，并且参数传递的完全一致，那么Native端将拒绝执行后续任务，直到下载中的任务执行完毕。
        // await EasyAppInstaller.instance.downloadAndInstallApk(
        //   fileUrl: widget.data['downloadURL'],
        //   fileDirectory: "apk",
        //   fileName: fileName,
        //   onDownloadingListener: (progress) {
        //     setState(() {
        //       this.progress = progress / 100;
        //     });
        //   },
        // );
      } catch (e) {
        UiUtil.toast("下载失败:$e");
      }
    }

    useEffect(() {
      if (direct) {
        download();
      }
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "软件更新",
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: <Widget>[
                const SizedBox(
                  height: 50,
                ),
                Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage(
                        "assets/logo.png",
                      ),
                      radius: 60,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Column(
                  children: [
                    Text(
                      "新版本 v${data['buildVersion']} build ${data['buildVersionNo']}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "更新日志：",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "${data['buildUpdateDescription'] ?? "暂无更新日志"}",
                          style: TextStyle(
                              color: AppTheme.of(context).placeholderColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              launchUrlString(data['downloadURL'],
                  mode: LaunchMode.externalApplication);
            },
            child: const Text(
              "使用浏览器下载",
              style: TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                  fontSize: 14),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          if (!downloading.value)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              child: OutlinedButton(
                onPressed: () {
                  download();
                },
                // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text(
                  "开始下载",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          if (downloading.value)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FAProgressBar(
                      backgroundColor: Colors.transparent,
                      progressColor: Colors.blue,
                      currentValue: (progress.value * 100).ceil(),
                      size: 64,
                      borderRadius: BorderRadius.circular(20),
                      displayText: '%',
                      displayTextStyle:
                          const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }
}
