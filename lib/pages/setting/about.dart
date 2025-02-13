import 'dart:io';
import 'package:dsm_helper/pages/common/browser.dart';
import 'package:dsm_helper/pages/setting/license.dart';
import 'package:dsm_helper/pages/setting/open_source.dart';
import 'package:dsm_helper/util/function.dart';
import 'package:dsm_helper/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  bool checking = false;
  PackageInfo? packageInfo;
  TapGestureRecognizer _licenseRecognizer = TapGestureRecognizer();
  TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer();
  @override
  void initState() {
    getInfo();
    super.initState();
  }

  getInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "关于${Util.instance.appName}",
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: <Widget>[
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(),
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(
                            "assets/logo.png",
                          ),
                          radius: 40,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Column(
                      children: [
                        Text(
                          "${Util.instance.appName}",
                          style: TextStyle(fontSize: 32),
                        ),
                        if (packageInfo != null)
                          Text(
                            "v${packageInfo?.version} build:${packageInfo?.buildNumber}",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                      ],
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(5)),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              "assets/icons/apaipai.png",
                              width: 20,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "青岛阿派派软件有限公司版权所有",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "用户协议",
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue),
                                recognizer: _licenseRecognizer
                                  ..onTap = () {
                                    FocusScope.of(context).unfocus();
                                    Navigator.of(context).push(
                                        CupertinoPageRoute(builder: (context) {
                                      return License();
                                    }));
                                  },
                              ),
                              TextSpan(text: "    "),
                              TextSpan(
                                text: "隐私政策",
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue),
                                recognizer: _privacyRecognizer
                                  ..onTap = () {
                                    FocusScope.of(context).unfocus();
                                    Navigator.of(context).push(
                                        CupertinoPageRoute(builder: (context) {
                                      return Browser(
                                        url: '${Util.instance.appUrl}/privacy',
                                        title: "隐私政策",
                                      );
                                    }));
                                  },
                              ),
                            ],
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (Util.instance.notReviewAccount) ...[
                  SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(5)),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          children: Util.instance.groups.channel?.map((e) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        "assets/icons/qq.png",
                                        width: 20,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        e.displayName,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Spacer(),
                                      OutlinedButton(
                                        onPressed: () {
                                          launchUrlString(e.key ?? '',
                                              mode: LaunchMode
                                                  .externalApplication);
                                        },
                                        child: Text("加入"),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList() ??
                              [],
                        )),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(5)),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          children: Util.instance.groups.qq?.map((e) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        "assets/icons/qq.png",
                                        width: 20,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        e.displayName,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Spacer(),
                                      OutlinedButton(
                                        onPressed: () {
                                          launchUrlString(
                                              'mqqopensdkapi://bizAgent/qm/qr?url=http%3A%2F%2Fqm.qq.com%2Fcgi-bin%2Fqm%2Fqr%3Ffrom%3Dapp%26p%3Dandroid%26jump_from%3Dwebapi%26k%3D${e.key}');
                                        },
                                        child: Text("加群"),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList() ??
                              [],
                        )),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(5)),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        children: Util.instance.groups.wechat?.map((e) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/icons/wechat.png",
                                      width: 20,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      e.displayName,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    OutlinedButton(
                                      onPressed: () {
                                        ClipboardData data = new ClipboardData(
                                            text: e.name ?? '');
                                        Clipboard.setData(data);
                                        Util.instance.toast("已复制到剪贴板");
                                      },
                                      child: Text("复制"),
                                    ),
                                  ],
                                ),
                              );
                            }).toList() ??
                            [],
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(5)),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/gitee.png",
                          width: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "${Util.instance.appName}开源地址",
                          style: TextStyle(fontSize: 16),
                        ),
                        Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(CupertinoPageRoute(builder: (context) {
                              return Browser(
                                url: "https://gitee.com/apaipai/dsm_helper",
                              );
                            }));
                          },
                          child: Text("查看"),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(5)),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        FlutterLogo(
                          size: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Powered by Flutter",
                          style: TextStyle(fontSize: 16),
                        ),
                        Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(builder: (context) {
                                return Browser(
                                  title: "Flutter官网",
                                  url: "https://flutter.dev",
                                );
                              }),
                            );
                          },
                          child: Text("官网"),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(5)),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/pub.png",
                          width: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "开源插件",
                          style: TextStyle(fontSize: 16),
                        ),
                        Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                  builder: (context) {
                                    return OpenSource();
                                  },
                                  settings: RouteSettings(name: "open_source")),
                            );
                          },
                          child: Text("详情"),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          if (Platform.isAndroid)
            Padding(
              padding: EdgeInsets.all(20),
              child: OutlinedButton(
                onPressed: () async {
                  if (checking) {
                    return;
                  }
                  setState(() {
                    checking = true;
                  });
                  await Util.instance.checkUpdate(true, context, force: true);
                  setState(() {
                    checking = false;
                  });
                },
                // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: checking
                    ? Center(
                        child: CupertinoActivityIndicator(
                          radius: 13,
                        ),
                      )
                    : Text(
                        "检查更新",
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
