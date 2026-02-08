import 'package:garden/pages/user/otp_bind.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class UserSetting extends StatefulWidget {
  const UserSetting({super.key});

  @override
  UserSettingState createState() => UserSettingState();
}

class UserSettingState extends State<UserSetting> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Map normalUser = {};
  bool loading = true;
  bool saving = false;
  Map<String, dynamic> changedData = {
    "username": "",
    "fullname": "",
    "email": "",
    "old_password": "",
    "password": "",
    "confirm_password": "",
  };
  @override
  void initState() {
    getNormalUser();
    super.initState();
  }

  getNormalUser() async {
    var res = await DsmApi.normalUser("get");
    if (res['success']) {
      setState(() {
        loading = false;
        normalUser = res['data'];
      });
      _usernameController.value =
          TextEditingValue(text: normalUser['username']);
      _fullnameController.value =
          TextEditingValue(text: normalUser['fullname']);
      _emailController.value = TextEditingValue(text: normalUser['email']);
    } else {
      UiUtil.toast("加载失败，code:${res['error']['code']}");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("个人设置"),
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: TextField(
                      controller: _usernameController,
                      onChanged: (v) => changedData['username'] = v,
                      enabled: false,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: '名称',
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: TextField(
                      controller: _fullnameController,
                      onChanged: (v) => changedData['fullname'] = v,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: '描述',
                      ),
                    ),
                  ),
                ),
                if (!normalUser['disallowchpasswd']) ...[
                  const SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: TextField(
                        onChanged: (v) => changedData['old_password'] = v,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '密码',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: TextField(
                        onChanged: (v) => changedData['password'] = v,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '新密码',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: TextField(
                        onChanged: (v) => changedData['confirm_password'] = v,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '确认密码',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: TextField(
                      controller: _emailController,
                      onChanged: (v) => changedData['email'] = v,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: '邮箱',
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    if (normalUser['OTP_enable']) {
                      setState(() {
                        normalUser['OTP_enable'] = false;
                        changedData['disableOTP'] = true;
                      });
                    } else {
                      Navigator.of(context)
                          .push(CupertinoPageRoute(
                              builder: (context) {
                                return OtpBind(normalUser['username'],
                                    normalUser['email']);
                              },
                              settings: const RouteSettings(name: "otp_bind")))
                          .then((res) {
                        if (res != null && res) {
                          setState(() {
                            normalUser['OTP_enable'] = true;
                          });
                        }
                      });
                    }
                  },
                  child: Card(
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: Row(
                        children: [
                          const Text("两步认证"),
                          const Spacer(),
                          if (normalUser['OTP_enable'])
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                OutlinedButton(
                  onPressed: () async {
                    if (saving) {
                      return;
                    }
                    setState(() {
                      saving = true;
                    });
                    Map<String, dynamic> data = {};
                    if (changedData['old_password'] == "") {
                      changedData.remove("old_password");
                      changedData.remove("password");
                      changedData.remove("confirm_password");
                    } else {
                      if (changedData['password'] == "") {
                        UiUtil.toast("请输入新密码");
                        return;
                      }
                      if (changedData['confirm_password'] !=
                          changedData['password']) {
                        UiUtil.toast("确认密码与新密码不一致");
                        return;
                      }
                    }
                    changedData.forEach((key, value) {
                      if (value is String) {
                        if (value.isNotEmpty && key != "confirm_password") {
                          data[key] = value;
                        }
                      } else if (value is bool) {
                        data[key] = value;
                      }
                    });
                    var res = await DsmApi.normalUser("set", changedData: data);
                    if (res['success']) {
                      UiUtil.toast("保存成功");
                      if (context.mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      }
                    } else {
                      setState(() {
                        saving = false;
                      });
                      UiUtil.toast("保存失败，原因:${res['error']['code']}");
                    }
                  },
                  child: saving
                      ? const CupertinoActivityIndicator(
                          radius: 13,
                        )
                      : const Text(
                          ' 保存 ',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
    );
  }
}
