import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/button_style.dart';
import 'package:garden/widgets/control_panel/permission_item.dart';
import 'package:garden/widgets/control_panel/quota_item.dart';
import 'package:garden/widgets/control_panel/user_group_item.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class UserDetail extends StatefulWidget {
  final Map user;
  const UserDetail(this.user, {super.key});
  @override
  UserDetailState createState() => UserDetailState();
}

class UserDetailState extends State<UserDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Map? user;
  List groups = [];
  List originGroups = [];
  List bandwidthControl = [];
  List volumes = [];
  List quotas = [];
  List permissions = [];
  String password = '';
  String confirmPassword = '';

  bool saving = false;
  @override
  void initState() {
    _tabController = TabController(length: 6, vsync: this);
    _nameController.value = TextEditingValue(text: widget.user['name']);
    _descriptionController.value =
        TextEditingValue(text: widget.user['description']);
    _emailController.value = TextEditingValue(text: widget.user['email']);
    setState(() {
      user = widget.user;
    });
    getData();
    super.initState();
  }

  Widget _buildVolumeItem(volume) {
    List shares = quotas
        .where((element) => element['volume'] == volume['volume_path'])
        .first['shares'];
    return GestureDetector(
      onTap: () {
        setState(() {
          // group['is_member'] = !group['is_member'];
        });
      },
      child: Card(
        shape: context.stadiumShapeBorder,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "${volume['display_name']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Label("${volume['description']}", Colors.lightBlueAccent),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ...shares.map((quota) => QuotaItem(quota: quota)),
            ],
          ),
        ),
      ),
    );
  }

  getGroup() async {
    var res = await DsmApi.userGroup(user?['name']);
    if (res['success']) {
      setState(() {
        groups = res['data']['groups'];
        originGroups = groups
            .where((group) => group['is_member'])
            .map((e) => e['name'])
            .toList();
      });
    }
  }

  getData() async {
    getGroup();
    var res = await DsmApi.userDetail(user?['name']);
    if (res['success']) {
      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.User":
              setState(() {
                user = item['data']['users'][0];
                user?['new_name'] = item['data']['users'][0]['name'];
              });
              break;
            case "SYNO.Core.User.PasswordExpiry":
              setState(() {
                // powerRecovery = item['data'];
              });
              break;
            case "SYNO.Core.Share.Permission":
              setState(() {
                permissions = item['data']['shares'];
              });
              break;
            case "SYNO.Core.Storage.Volume":
              setState(() {
                volumes = item['data']['volumes'];
              });
              break;
            case "SYNO.Core.BandwidthControl":
              setState(() {
                bandwidthControl = item['data']['bandwidths'];
              });
              break;
            case "SYNO.Core.OTP.Admin":
              setState(() {});
              break;
            case "SYNO.Core.FileServ.SMB":
              setState(() {});
              break;
            case "SYNO.Core.Quota":
              setState(() {
                quotas = item['data']['user_quota'];
              });
              break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("${widget.user['name']}"),
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: TabBar(
              dividerHeight: 0,
              isScrollable: true,
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.brightnessOf(context) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: const BubbleTabIndicator(),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("信息"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("用户群组"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("权限"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("空间配额"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("应用程序"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("速度限制"),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          controller: _nameController,
                          onChanged: (v) => user?['new_name'] = v,
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          controller: _descriptionController,
                          onChanged: (v) => user?['description'] = v,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '描述',
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          controller: _emailController,
                          onChanged: (v) => user?['email'] = v,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '电子邮件',
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          onChanged: (v) => password = v,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '修改密码',
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          obscureText: true,
                          onChanged: (v) => confirmPassword = v,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '确认密码',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          user?['cannot_chg_passwd'] =
                              !user?['cannot_chg_passwd'];
                        });
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          child: Row(
                            children: [
                              const Text("不允许此用户修改密码"),
                              const Spacer(),
                              if (user?['cannot_chg_passwd'] ?? false)
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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          // user['passwd_never_expire'] = !user['passwd_never_expire'];
                        });
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          child: Row(
                            children: [
                              const Text("密码始终有效"),
                              const Spacer(),
                              if (user?['passwd_never_expire'] ?? false)
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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (user?['expired'] != "normal") {
                            user?['expired'] = "normal";
                          } else {
                            user?['expired'] = "now";
                          }
                        });
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "停用此用户账户",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  if (user?['expired'] != "normal")
                                    Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                ],
                              ),
                              if (user?['expired'] != "normal")
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  margin: const EdgeInsets.only(top: 20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                user?['expired'] = "now";
                                              });
                                            },
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                  side: const BorderSide(),
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                    AppConstants.paddingSmall),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          "立即",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              height: 1.6),
                                                        ),
                                                        const Spacer(),
                                                        if (user?['expired'] ==
                                                            "now")
                                                          const Icon(
                                                            CupertinoIcons
                                                                .checkmark_alt,
                                                            color: Color(
                                                                0xffff9813),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: GestureDetector(
                                            onTap: () {
                                              DatePicker.showDatePicker(context,
                                                  locale: LocaleType.zh,
                                                  currentTime: DateTime.now(),
                                                  onConfirm: (v) {
                                                setState(() {
                                                  user?['expired'] =
                                                      v.format("Y-m-d");
                                                  Log.info(user?['expired']);
                                                });
                                              });
                                            },
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                  side: const BorderSide(),
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                    AppConstants.paddingSmall),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "${user?['expired'] == "now" ? "到期于：" : user?['expired']}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16,
                                                                  height: 1.6),
                                                        ),
                                                        const Spacer(),
                                                        if (user?['expired'] !=
                                                            "now")
                                                          const Icon(
                                                            CupertinoIcons
                                                                .checkmark_alt,
                                                            color: Color(
                                                                0xffff9813),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, i) {
                    return UserGroupItem(
                      group: groups[i],
                      onTap: () {
                        setState(() {
                          groups[i]['is_member'] = !groups[i]['is_member'];
                        });
                      },
                    );
                  },
                  itemCount: groups.length,
                  separatorBuilder: (context, i) {
                    return const SizedBox(
                      height: 20,
                    );
                  },
                ),
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, i) {
                    return PermissionItem(permission: permissions[i]);
                  },
                  itemCount: permissions.length,
                  separatorBuilder: (context, i) {
                    return const SizedBox(
                      height: 20,
                    );
                  },
                ),
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, i) {
                    return _buildVolumeItem(volumes[i]);
                  },
                  itemCount: volumes.length,
                  separatorBuilder: (context, i) {
                    return const SizedBox(
                      height: 20,
                    );
                  },
                ),
                ListView(),
                ListView(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: OutlinedButton(
                onPressed: () async {
                  if (password.isNotBlank || confirmPassword.isNotBlank) {
                    if (password != confirmPassword) {
                      UiUtil.toast("密码输入不一致");
                      return;
                    }
                    if (password != '' && password.length < 6) {
                      UiUtil.toast("密码最低6位");
                      return;
                    }
                    user?['password'] = password;
                  }

                  //对比当前groups与原始groups
                  List newGroups = groups
                      .where((group) => group['is_member'])
                      .map((e) => e['name'])
                      .toList();
                  List addGroup = newGroups
                      .where((group) => !originGroups.contains(group))
                      .toList();
                  List removeGroup = originGroups
                      .where((group) => !newGroups.contains(group))
                      .toList();

                  setState(() {
                    saving = true;
                  });

                  var res =
                      await DsmApi.userSave(user ?? {}, addGroup, removeGroup);
                  setState(() {
                    saving = false;
                  });
                  if (res['success']) {
                    widget.user['name'] = user?['new_name'];
                    widget.user['email'] = user?['email'];
                    UiUtil.toast("保存成功");
                  } else {
                    UiUtil.toast("保存失败,代码${res['error']['code']}");
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
            ),
          ),
        ],
      ),
    );
  }
}
