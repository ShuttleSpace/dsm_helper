import 'dart:async';

import 'package:cool_ui/cool_ui.dart';
import 'package:garden/pages/common/browser.dart' as dsm;
import 'package:garden/pages/setting/vip_login.dart';
import 'package:garden/pages/setting/vip_record.dart';
import 'package:garden/providers/flux_provider.dart';
import 'package:garden/themes/app_theme.dart';
import 'package:garden/util/function.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart';
import 'package:provider/provider.dart';

class Vip extends StatefulWidget {
  const Vip();

  @override
  State<Vip> createState() => _VipState();
}

class _VipState extends State<Vip> {
  DateTime noAdTime = DateTime.now();
  DateTime vipExpireTime = DateTime.now();
  DateTime lastVideoTime = DateTime.now();
  bool isLogin = true;
  bool isForever = true;
  String outTradeNo = "";
  String userToken = "";
  Map activity = {};
  Timer? timer;
  @override
  void initState() {
    if (this.mounted) {
      context.read<FluwxProvider>().wx.addSubscriber(wechatListener);
    }
    // weChatResponseEventHandler
    //     .distinct((a, b) => a == b)
    //     .listen(wechatListener);
    initData();
    getActivity();

    super.initState();
  }

  void wechatListener(res) {
    if (res is WeChatAuthResponse) {
      setState(() {
        login(res.code ?? '');
      });
    } else if (res is WeChatPaymentResponse) {
      setState(() {
        if (res.isSuccessful) {
          checkPayment();
        } else {
          if (res.errCode == -2) {
            Util.instance.toast("已取消支付");
          } else {
            Util.instance.toast(
                res.errStr?.isNotBlank == true ? res.errStr ?? '' : '支付失败');
          }
        }
      });
    }
  }

  checkPayment() async {
    var hide = showWeuiLoadingToast(context: context, backButtonClose: true);
    timer = Timer.periodic(Duration(seconds: 1), (_) async {
      var res = await Util.instance.post(
          "${Util.instance.appUrl}/payment/check",
          data: {"out_trade_no": outTradeNo});
      if (res['code'] == 1) {
        Util.instance.toast("支付成功");
        timer?.cancel();
        initData(tips: true);
        hide();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  initData({bool tips = false}) async {
    String noAdTimeStr = await Util.instance.getStorage("no_ad_time") ?? '';
    if (noAdTimeStr.isNotBlank) {
      noAdTime = DateTime.parse(noAdTimeStr);
      if (noAdTime.isBefore(DateTime.now())) {
        Util.instance.removeStorage("no_ad_time");
        noAdTime = DateTime.now();
      }
    }
    String lastVideoTimeStr =
        await Util.instance.getStorage("last_video_time") ?? '';
    if (lastVideoTimeStr.isNotBlank) {
      setState(() {
        lastVideoTime = DateTime.parse(lastVideoTimeStr);
      });
    }
    userToken = await Util.instance.getStorage("user_token") ?? '';
    if (userToken.isNotBlank) {
      var res = await Util.instance
          .post("${Util.instance.appUrl}/vip/info", data: {"token": userToken});
      if (res['code'] == 1) {
        isLogin = true;
        if (res['data']['is_forever'] == 1) {
          isForever = Util.instance.vipForever = true;
        }
        // isForever = Util.vipForever = true;
        if (res['data']['vip_expire_time'] != null) {
          Util.instance.vipExpireTime =
              vipExpireTime = DateTime.parse(res['data']['vip_expire_time']);
          if (vipExpireTime.isAfter(noAdTime)) {
            noAdTime = vipExpireTime;
          }
        }
      }
    }
    setState(() {});
  }

  login(String code) async {
    var hide = showWeuiLoadingToast(context: context);
    try {
      var res = await Util.instance
          .post("${Util.instance.appUrl}/login/app", data: {"code": code});
      if (res['code'] == 1) {
        Util.instance.setStorage("user_openid", res['data']['openid']);
        Util.instance.setStorage("user_token", res['data']['token']);
        setState(() {
          isLogin = true;
        });
        Util.instance.toast("登录成功");
        initData();
      } else {
        Util.instance.toast(res['msg']);
      }
    } catch (e) {
      Util.instance.toast("登录失败：${e.toString()}");
    } finally {
      hide();
    }
  }

  playVideo() async {
    Navigator.of(context).pop();
    var hide = showWeuiLoadingToast(context: context, message: Text("广告加载中"));
    try {
      setState(() {
        noAdTime = noAdTime.add(Duration(days: 1000 * 365));
      });
      lastVideoTime = DateTime.now();
      // Util.toast("恭喜您成功获得3天免广告特权");
      Util.instance.setStorage("no_ad_time", noAdTime.format("Y-m-d H:i:s"));
      Util.instance
          .setStorage("last_video_time", lastVideoTime.format("Y-m-d H:i:s"));
    } catch (e) {
      Util.instance.toast("广告播放失败");
    } finally {
      hide();
    }
  }

  close3() {
    if (lastVideoTime.isSameDay(DateTime.now())) {
      Util.instance.toast("今天已经领取过，明天再来吧~");
      return;
    }
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    side: BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                margin: EdgeInsets.symmetric(horizontal: 50),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "关闭3天广告",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                            side: BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        child: Text("通过观看视频广告，可关闭3天开屏广告"),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: playVideo,
                              child: Text(
                                "观看广告",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "取消",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  close7() {
    if (!isLogin) {
      loginDialog();
    } else {
      String code = "";
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return Material(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin: EdgeInsets.symmetric(horizontal: 50),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "兑换码",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                          '可关注群晖助手公众号，在聊天窗口回复"10006"使用积分获取兑换码',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.normal),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Card(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(),
                              borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              onChanged: (v) => code = v,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "请输入兑换码",
                                labelText: "兑换码",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  if (code.trim() == "") {
                                    Util.instance.toast("请输入兑换码");
                                    return;
                                  }
                                  var res = await Util.instance.post(
                                      "${Util.instance.appUrl}/vip/exchange",
                                      data: {
                                        "token": userToken,
                                        "code": code.trim()
                                      });
                                  if (res['code'] == 0) {
                                    Util.instance.toast(res['msg']);
                                  } else {
                                    Util.instance.toast("兑换成功");
                                    initData(tips: true);
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text(
                                  "兑换",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "取消",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  wxLogin() {
    context
        .read<FluwxProvider>()
        .wx
        .authBy(which: NormalAuth(scope: "snsapi_userinfo"));
  }

  loginDialog({bool alert = true}) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    side: BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                margin: EdgeInsets.symmetric(horizontal: 50),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "温馨提示",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Text(
                        alert ? "为了防止APP卸载后开通记录丢失，此功能需登录账号后使用" : "请选择登录方式",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                wxLogin();
                                Navigator.of(context).pop();
                              },
                              child: Image.asset(
                                "assets/icons/wechat.png",
                                width: 25,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                    CupertinoPageRoute(builder: (context) {
                                  return VipLogin();
                                })).then((res) {
                                  if (res != null && res) {
                                    initData();
                                  }
                                });
                              },
                              child: Text(
                                "账号登录",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "取消",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> closeAd(String type) async {
    if (!isLogin) {
      loginDialog();
    } else if (isForever) {
      Util.instance.toast("您已开通永久免广告特权，无需继续购买");
    } else {
      var hide = showWeuiLoadingToast(context: context);

      try {
        await payOrder(type);
      } finally {
        hide();
      }
    }
  }

  getActivity() async {
    var res =
        await Util.instance.post("${Util.instance.appUrl}/activity/activity");
    if (res['code'] == 1) {
      activity = res['data'];
      setState(() {});
    } else {
      Util.instance.toast(res['msg']);
    }
  }

  payOrder(String type) async {
    var res = await Util.instance.post("${Util.instance.appUrl}/payment/wechat",
        data: {"token": userToken, "type": type});
    if (res['code'] == 1) {
      var data = res['data'];
      outTradeNo = data['out_trade_no'];
      context.read<FluwxProvider>().wx.pay(
            which: Payment(
                appId: data['appid'],
                partnerId: data['partnerid'],
                prepayId: data['prepayid'],
                packageValue: data['package'],
                nonceStr: data['noncestr'],
                timestamp: int.parse(data['timestamp']),
                sign: data['sign']),
          );
    } else {
      Util.instance.toast(res['msg']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("关闭广告"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                if (!isLogin) {
                  loginDialog(alert: false);
                } else {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return VipRecord();
                  }));
                }
              },
              child: Text(
                isLogin ? "开通记录" : "恢复购买",
                style: TextStyle(color: AppTheme.of(context).titleColor),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          if (activity['banner'] != null)
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () {
                  if (activity['url'] != null && activity['url'] != '') {
                    Navigator.of(context)
                        .push(CupertinoPageRoute(builder: (context) {
                      return dsm.Browser(
                        url: activity['url'],
                      );
                    }));
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ExtendedImage.network(activity['banner']),
                ),
              ),
            ),
          Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("广告状态："),
                  if (isForever == false)
                    Text("未关闭")
                  else if (isForever)
                    Text("永久关闭", style: TextStyle(color: Colors.red))
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: "关闭至"),
                          TextSpan(
                              text: "${noAdTime.format("Y-m-d H:i:s")}",
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          if (isForever)
            Text(
              "您已开通永久免广告特权，为给您带来更清爽的体验，已为您隐藏设置页面的关闭广告入口，您可以点击设置页面右上角齿轮找到关闭广告页面。",
              style: TextStyle(color: Colors.red),
            )
          else if (vipExpireTime.difference(DateTime.now()).inDays > 7)
            Text(
              "您的免广告剩余时长大于7天，为给您带来更清爽的体验，已为您隐藏设置页面的关闭广告入口，您可以点击设置页面右上角齿轮找到关闭广告页面。",
              style: TextStyle(color: Colors.red),
            ),
          if (activity['description'] != null)
            Text("${activity['description']}"),
          NoAdButton(
            "关闭3天",
            price: "观看广告",
            onPressed: close3,
          ),
          SizedBox(
            height: 20,
          ),
          if (!isForever) ...[
            Text("注意：以下方式购买的免广告时长与关闭3天不累加，将取最长时间作为实际免广告时长。"),
            NoAdButton(
              "免广告兑换码",
              price: "兑换",
              onPressed: close7,
            ),
            NoAdButton(
              "关闭1月",
              price: "￥1.99", //￥1.99
              onPressed: () {
                closeAd("month");
              },
            ),
            NoAdButton(
              "关闭1年",
              price: "￥14.99", // ￥14.99
              onPressed: () {
                closeAd("year");
              },
            ),
            NoAdButton(
              "永久关闭",
              price: "￥29.99", // ￥29.99
              onPressed: () {
                closeAd("forever");
              },
            ),
          ],
        ],
      ),
    );
  }
}

class NoAdButton extends StatelessWidget {
  const NoAdButton(this.title, {this.price, this.onPressed});
  final String? title;
  final String? price;
  final Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.only(top: 20),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title ?? ''),
            Spacer(),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(
                price ?? '',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
