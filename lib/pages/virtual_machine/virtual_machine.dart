import 'dart:async';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/widgets/virtual_machine/host_item.dart';
import 'package:garden/widgets/virtual_machine/guest_item.dart';
import 'package:garden/widgets/virtual_machine/repo_item.dart';
import 'package:garden/widgets/virtual_machine/cluster_summary_card.dart';
import 'package:garden/widgets/virtual_machine/power_confirm_dialog.dart';

class VirtualMachine extends StatefulWidget {
  const VirtualMachine({super.key});

  @override
  VirtualMachineState createState() => VirtualMachineState();
}

class VirtualMachineState extends State<VirtualMachine> {
  late Timer timer;
  bool loading = true;
  bool hostLoading = true;
  bool guestLoading = true;
  bool repoLoading = true;
  Map<String, bool> powerLoading = {};
  dynamic cluster;
  List hosts = [];
  List guests = [];
  List repos = [];
  int _currentIndex = 0;

  @override
  void initState() {
    getData();
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      getData();
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  power(guest, String action) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return PowerConfirmDialog(
          action: action,
          onConfirm: () async {
            setState(() {
              powerLoading[guest['id']] = true;
            });
            var res = await DsmApi.vmmPower(guest['id'], action);
            if (res['success']) {
              UiUtil.toast("请求发送成功");
              getGuests();
            } else {
              UiUtil.toast("请求发送失败，代码：${res['error']['code']}");
            }
            setState(() {
              powerLoading[guest['id']] = false;
            });
          },
        );
      },
    );
  }

  getData() async {
    var res = await DsmApi.cluster("get");
    if (res['success']) {
      if (mounted) {
        setState(() {
          cluster = res['data'];
          loading = false;
        });
      }
      if (_currentIndex == 0) {
        getHosts();
      } else if (_currentIndex == 1) {
        getGuests();
      } else if (_currentIndex == 2) {
        getRepos();
      }
    }
  }

  getHosts() async {
    var res = await DsmApi.cluster("get_host");
    if (res['success']) {
      if (mounted) {
        setState(() {
          hosts = res['data']['hosts'];
          hosts.sort((a, b) {
            return a['name'].compareTo(b['name']);
          });
          hostLoading = false;
        });
      }
    }
  }

  getGuests() async {
    var res = await DsmApi.cluster("get_guest");
    if (res['success']) {
      if (mounted) {
        setState(() {
          guests = res['data']['guests'];
          guests.sort((a, b) {
            return a['name'].compareTo(b['name']);
          });
          guestLoading = false;
        });
      }
    }
  }

  getRepos() async {
    var res = await DsmApi.cluster("get_repo");
    if (res['success']) {
      if (mounted) {
        setState(() {
          repos = res['data']['repos'];
          repos.sort((a, b) {
            return a['name'].compareTo(b['name']);
          });
          repoLoading = false;
        });
      }
    }
  }

  Widget _buildHostItem(host) {
    return HostItem(host: host);
  }

  Widget _buildGuestItem(guest) {
    if (powerLoading[guest['id']] == null) {
      powerLoading[guest['id']] = false;
    }
    return GuestItem(
      guest: guest,
      powerLoading: powerLoading,
      onPowerAction: (action) => power(guest, action),
      onPowerOn: () async {
        setState(() {
          powerLoading[guest['id']] = true;
        });
        var check = await DsmApi.checkPowerOn(guest['id']);
        Log.info(check);
        if (check['success']) {
          var res = await DsmApi.vmmPower(guest['id'], "poweron");
          if (res['success']) {
            UiUtil.toast("开机请求发送成功");
            getGuests();
          } else {
            UiUtil.toast("开机请求发送失败，代码：${res['error']['code']}");
          }
        } else {
          UiUtil.toast("无法开机");
        }
        setState(() {
          powerLoading[guest['id']] = false;
        });
      },
    );
  }

  Widget _buildRepoItem(repo) {
    return RepoItem(repo: repo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("Virtual Machine Manager"),
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClusterSummaryCard(
                            title: "主机",
                            totalCount: cluster['host_summ']['error'] +
                                cluster['host_summ']['healthy'] +
                                cluster['host_summ']['warning'],
                            errorCount: cluster['host_summ']['error'],
                            warningCount: cluster['host_summ']['warning'],
                            healthyCount: cluster['host_summ']['healthy'],
                            onTap: () {
                              setState(() {
                                _currentIndex = 0;
                              });
                              getHosts();
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ClusterSummaryCard(
                            title: "虚拟机",
                            totalCount: cluster['guest_summ']['error'] +
                                cluster['guest_summ']['healthy'] +
                                cluster['guest_summ']['warning'],
                            errorCount: cluster['guest_summ']['error'],
                            warningCount: cluster['guest_summ']['warning'],
                            healthyCount: cluster['guest_summ']['healthy'],
                            onTap: () {
                              setState(() {
                                _currentIndex = 1;
                              });
                              getGuests();
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ClusterSummaryCard(
                            title: "存储",
                            totalCount: cluster['repo_summ']['error'] +
                                cluster['repo_summ']['healthy'] +
                                cluster['repo_summ']['warning'],
                            errorCount: cluster['repo_summ']['error'],
                            warningCount: cluster['repo_summ']['warning'],
                            healthyCount: cluster['repo_summ']['healthy'],
                            onTap: () {
                              setState(() {
                                _currentIndex = 2;
                              });
                              getRepos();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      hostLoading
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return _buildHostItem(hosts[i]);
                              },
                              itemCount: hosts.length,
                            ),
                      guestLoading
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return _buildGuestItem(guests[i]);
                              },
                              itemCount: guests.length,
                            ),
                      repoLoading
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return _buildRepoItem(repos[i]);
                              },
                              itemCount: repos.length,
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
