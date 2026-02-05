import 'package:garden/util/http_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class UserGroups extends StatefulWidget {
  const UserGroups({super.key});

  @override
  UserGroupsState createState() => UserGroupsState();
}

class UserGroupsState extends State<UserGroups> {
  List groups = [];
  bool loading = true;
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await Api.userGroups();
    if (res['success']) {
      setState(() {
        loading = false;
        groups = res['data']['groups'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("用户群组"),
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
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, i) {
                return _buildGroupItem(groups[i]);
              },
              itemCount: groups.length,
            ),
    );
  }
}
