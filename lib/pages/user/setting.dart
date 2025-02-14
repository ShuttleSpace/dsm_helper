import 'package:humphrey_garden/pages/user/otp_bind.dart';
import 'package:humphrey_garden/util/function.dart';
import 'package:humphrey_garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserSetting extends StatefulWidget {
  @override
  _UserSettingState createState() => _UserSettingState();
}

class _UserSettingState extends State<UserSetting> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _fullnameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
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
    var res = await Api.normalUser("get");
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
      Util.instance.toast("加载失败，code:${res['error']['code']}");
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("个人设置"),
      ),
      body: loading
          ? Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : ListView(
              padding: EdgeInsets.all(20),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _usernameController,
                      onChanged: (v) => changedData['username'] = v,
                      enabled: false,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: '名称',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _fullnameController,
                      onChanged: (v) => changedData['fullname'] = v,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: '描述',
                      ),
                    ),
                  ),
                ),
                if (!normalUser['disallowchpasswd']) ...[
                  SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(36)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (v) => changedData['old_password'] = v,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: '密码',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(36)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (v) => changedData['password'] = v,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: '新密码',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(36)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (v) => changedData['confirm_password'] = v,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: '确认密码',
                        ),
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
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _emailController,
                      onChanged: (v) => changedData['email'] = v,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: '邮箱',
                      ),
                    ),
                  ),
                ),
                SizedBox(
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
                              settings: RouteSettings(name: "otp_bind")))
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
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(36)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text("两步认证"),
                          Spacer(),
                          if (normalUser['OTP_enable'])
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: Color(0xffff9813),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
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
                        Util.instance.toast("请输入新密码");
                        return;
                      }
                      if (changedData['confirm_password'] !=
                          changedData['password']) {
                        Util.instance.toast("确认密码与新密码不一致");
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
                    var res = await Api.normalUser("set", changedData: data);
                    if (res['success']) {
                      Util.instance.toast("保存成功");
                      Navigator.of(context).pop(true);
                    } else {
                      setState(() {
                        saving = false;
                      });
                      Util.instance.toast("保存失败，原因:${res['error']['code']}");
                    }
                  },
                  child: saving
                      ? CupertinoActivityIndicator(
                          radius: 13,
                        )
                      : Text(
                          ' 保存 ',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
    );
  }
}
