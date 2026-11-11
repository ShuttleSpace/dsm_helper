import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/control_panel/permission_item.dart';
import 'package:garden/widgets/control_panel/quota_item.dart';
import 'package:garden/widgets/control_panel/user_group_item.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class UserDetail extends HookWidget {
  final Map user;
  const UserDetail(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 6, vsync: tickerProvider),
      const [],
    );
    final nameController = useTextEditingController(text: user['name']);
    final descriptionController =
        useTextEditingController(text: user['description']);
    final emailController = useTextEditingController(text: user['email']);
    final userInfo = useSignal<Map?>(user);
    final groups = useSignal<List>([]);
    final originGroups = useSignal<List>([]);
    final bandwidthControl = useSignal<List>([]);
    final volumes = useSignal<List>([]);
    final quotas = useSignal<List>([]);
    final permissions = useSignal<List>([]);
    final password = useSignal('');
    final confirmPassword = useSignal('');
    final saving = useSignal(false);

    getGroup() async {
      var res = await DsmApi.userGroup(userInfo.value?['name']);
      if (res['success']) {
        groups.value = res['data']['groups'];
        originGroups.value = groups.value
            .where((group) => group['is_member'])
            .map((e) => e['name'])
            .toList();
      }
    }

    getData() async {
      getGroup();
      var res = await DsmApi.userDetail(userInfo.value?['name']);
      if (res['success']) {
        List result = res['data']['result'];
        for (var item in result) {
          if (item['success'] == true) {
            switch (item['api']) {
              case "SYNO.Core.User":
                userInfo.value = item['data']['users'][0];
                userInfo.value?['new_name'] = item['data']['users'][0]['name'];
                break;
              case "SYNO.Core.User.PasswordExpiry":
                break;
              case "SYNO.Core.Share.Permission":
                permissions.value = item['data']['shares'];
                break;
              case "SYNO.Core.Storage.Volume":
                volumes.value = item['data']['volumes'];
                break;
              case "SYNO.Core.BandwidthControl":
                bandwidthControl.value = item['data']['bandwidths'];
                break;
              case "SYNO.Core.OTP.Admin":
                break;
              case "SYNO.Core.FileServ.SMB":
                break;
              case "SYNO.Core.Quota":
                quotas.value = item['data']['user_quota'];
                break;
            }
          }
        }
      }
    }

    Widget buildVolumeItem(volume) {
      List shares = quotas.value
          .where((element) => element['volume'] == volume['volume_path'])
          .first['shares'];
    return GestureDetector(
      onTap: () {},
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
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

    useEffect(() {
      getData();
      return () {
        tabController.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("${user['name']}"),
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
              controller: tabController,
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
              controller: tabController,
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
                          controller: nameController,
                          onChanged: (v) => userInfo.value?['new_name'] = v,
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
                          controller: descriptionController,
                          onChanged: (v) => userInfo.value?['description'] = v,
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
                          controller: emailController,
                          onChanged: (v) => userInfo.value?['email'] = v,
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
                          onChanged: (v) => password.value = v,
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
                          onChanged: (v) => confirmPassword.value = v,
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
                        userInfo.value?['cannot_chg_passwd'] =
                            !userInfo.value?['cannot_chg_passwd'];
                        userInfo.notifyListeners();
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
                              if (userInfo.value?['cannot_chg_passwd'] ?? false)
                                const Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: AppColors.primaryAction,
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
                      onTap: () {},
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
                              if (userInfo.value?['passwd_never_expire'] ?? false)
                                const Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: AppColors.primaryAction,
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
                        if (userInfo.value?['expired'] != "normal") {
                          userInfo.value?['expired'] = "normal";
                        } else {
                          userInfo.value?['expired'] = "now";
                        }
                        userInfo.notifyListeners();
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
                                  if (userInfo.value?['expired'] != "normal")
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                              if (userInfo.value?['expired'] != "normal")
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
                                              userInfo.value?['expired'] = "now";
                                              userInfo.notifyListeners();
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
                                                        if (userInfo.value?['expired'] ==
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
                                                userInfo.value?['expired'] =
                                                    v.format("Y-m-d");
                                                Log.info(
                                                    userInfo.value?['expired']);
                                                userInfo.notifyListeners();
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
                                                          "${userInfo.value?['expired'] == "now" ? "到期于：" : userInfo.value?['expired']}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16,
                                                                  height: 1.6),
                                                        ),
                                                        const Spacer(),
                                                        if (userInfo.value?['expired'] !=
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
                      group: groups.value[i],
                      onTap: () {
                        groups.value[i]['is_member'] =
                            !groups.value[i]['is_member'];
                        groups.notifyListeners();
                      },
                    );
                  },
                  itemCount: groups.value.length,
                  separatorBuilder: (context, i) {
                    return const SizedBox(
                      height: 20,
                    );
                  },
                ),
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, i) {
                    return PermissionItem(permission: permissions.value[i]);
                  },
                  itemCount: permissions.value.length,
                  separatorBuilder: (context, i) {
                    return const SizedBox(
                      height: 20,
                    );
                  },
                ),
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, i) {
                    return buildVolumeItem(volumes.value[i]);
                  },
                  itemCount: volumes.value.length,
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
                  if (password.value.isNotBlank ||
                      confirmPassword.value.isNotBlank) {
                    if (password.value != confirmPassword.value) {
                      UiUtil.toast("密码输入不一致");
                      return;
                    }
                    if (password.value != '' && password.value.length < 6) {
                      UiUtil.toast("密码最低6位");
                      return;
                    }
                    userInfo.value?['password'] = password.value;
                  }

                  //对比当前groups与原始groups
                  List newGroups = groups.value
                      .where((group) => group['is_member'])
                      .map((e) => e['name'])
                      .toList();
                  List addGroup = newGroups
                      .where((group) => !originGroups.value.contains(group))
                      .toList();
                  List removeGroup = originGroups.value
                      .where((group) => !newGroups.contains(group))
                      .toList();

                  saving.value = true;

                  var res = await DsmApi.userSave(
                      userInfo.value ?? {}, addGroup, removeGroup);
                  saving.value = false;
                  if (res['success']) {
                    user['name'] = userInfo.value?['new_name'];
                    user['email'] = userInfo.value?['email'];
                    UiUtil.toast("保存成功");
                  } else {
                    UiUtil.toast("保存失败,代码${res['error']['code']}");
                  }
                },
                child: saving.value
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
