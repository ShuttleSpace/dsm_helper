import 'package:garden/pages/update/update.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/http_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class UpdateDialog extends StatelessWidget {
  final Map updateInfo;
  final PackageInfo? packageInfo;
  const UpdateDialog(this.updateInfo, this.packageInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cupertinoTheme = CupertinoTheme.of(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 175,
                  width: double.infinity,
                  child: WaveWidget(
                    config: CustomConfig(
                      colors: [
//                    Colors.white70,
                        Colors.white54,
                        Colors.white30,
                        Colors.white,
                      ],
                      durations: [12000, 8000, 5000],
                      heightPercentages: [0.26, 0.28, 0.31],
//                  blur: MaskFilter.blur(BlurStyle.solid, 16.0),
                    ),
                    backgroundColor: cupertinoTheme.primaryColor,
                    size: const Size(double.infinity, double.infinity),
                    waveAmplitude: 0,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 300,
                      height: 79,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 107.5, top: 8.5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              "有更新啦!",
                              style: TextStyle(
                                  fontSize: 24, color: AppColors.updateTitle),
                            ),
                            const SizedBox(
                              height: 3.5,
                            ),
                            Text(
                              "V${packageInfo?.version} build ${packageInfo?.buildNumber} → V${updateInfo['buildVersion']} build ${updateInfo['buildVersionNo']}",
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.updateTitle),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 300,
                      constraints: const BoxConstraints(
                        minHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20)),
                      ),
                      padding:
                          const EdgeInsets.only(left: 23, right: 23, top: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "更新日志：",
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                height: 1.5),
                          ),
                          Text(
                            "${updateInfo['buildUpdateDescription']}",
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                height: 2),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                top: -25,
                left: 11,
                child: Image.asset(
                  "assets/icons/rocket.png",
                  width: 81.5,
                ),
              ),
              Positioned(
                bottom: 83,
                child: Container(
                  width: 300,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          List<String> ignoredVersions = [];
                          String ignoredVersionsString = await HttpUtil.instance
                                  .getStorage("ignoredVersions") ??
                              '';
                          if (ignoredVersionsString.isNotBlank) {
                            ignoredVersions = ignoredVersionsString.split(",");
                          }
                          ignoredVersions.add(packageInfo?.buildNumber ?? '');
                          StorageUtil.setString(
                              "ignoredVersions", ignoredVersions.join(","));
                        },
                        color: cupertinoTheme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 29, vertical: 5),
                        minimumSize: const Size(0, 0),
                        child: Text(
                          "忽略此版本",
                          style: TextStyle(
                              fontSize: 17.5,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: .6)),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      CupertinoButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(CupertinoPageRoute(
                              builder: (context) {
                                return Update(updateInfo, direct: true);
                              },
                              settings: const RouteSettings(name: "update")));
                        },
                        color: cupertinoTheme.primaryColor,
                        borderRadius: BorderRadius.circular(50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 29, vertical: 5),
                        minimumSize: const Size(0, 0),
                        child: Text(
                          "立即更新",
                          style: TextStyle(
                              fontSize: 17.5, color: theme.colorScheme.surface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                child: Container(
                  width: 300,
                  alignment: Alignment.center,
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(50),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 29, vertical: 5),
                    minimumSize: const Size(0, 0),
                    child: ImageIcon(
                      const AssetImage("assets/icons/close.png"),
                      size: 48.5,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
