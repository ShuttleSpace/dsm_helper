import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/control_panel/users/user_detail.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';

class Users extends StatefulWidget {
  const Users({super.key});

  @override
  UsersState createState() => UsersState();
}

class UsersState extends State<Users> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List users = [];
  List groups = [];
  bool loading = true;
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    var res = await dsmCoreUserList();
    if (res['success']) {
      setState(() {
        users = res['data']['users'];
      });
    } else {
      UiUtil.toast("加载失败");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
    var group = await dsmCoreGroupList();
    if (group['success']) {
      setState(() {
        loading = false;
        groups = group['data']['groups'];
      });
    } else {
      UiUtil.toast("加载失败");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildGroupItem(group) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin:
          const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${group['name']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (group['description'] != "")
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        "${group['description']}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(user) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(CupertinoPageRoute(
                builder: (context) {
                  return UserDetail(user);
                },
                settings: const RouteSettings(name: "user_detail")))
            .then((value) {
          setState(() {});
        });
      },
      child: Card(
        shape: context.stadiumShapeBorder,
        margin:
            const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (user['expired'] == 'normal')
                          const Label("正常", Colors.green)
                        else
                          const Label("停用", Colors.red),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          "${user['name']}",
                          style: const TextStyle(fontSize: 16),
                        )
                      ],
                    ),
                    if (user['email'] != "")
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          "${user['email']}",
                        ),
                      ),
                    if (user['description'] != "")
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          "${user['description']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
            connectionStore.dsmVersion.watch(context) < 7 ? "用户账户" : "用户与群组"),
      ),
      body: loading
          ? Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: .7),
              child: const Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                ),
              ),
            )
          : Column(
              children: [
                if (connectionStore.dsmVersion >= 7)
                  Card(
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary)),
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: TabBar(
                      dividerHeight: 0,
                      isScrollable: false,
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: Theme.brightnessOf(context) == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicator: const BubbleTabIndicator(),
                      tabs: const [
                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("用户账号"),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("用户群组"),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: connectionStore.dsmVersion < 7
                      ? ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemBuilder: (context, i) {
                            return _buildUserItem(users[i]);
                          },
                          itemCount: users.length,
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return _buildUserItem(users[i]);
                              },
                              itemCount: users.length,
                            ),
                            ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return _buildGroupItem(groups[i]);
                              },
                              itemCount: groups.length,
                            )
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
