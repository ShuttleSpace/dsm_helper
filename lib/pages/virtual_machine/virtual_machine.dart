import 'dart:async';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/constants/app_constants.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/widgets/virtual_machine/host_item.dart';
import 'package:garden/widgets/virtual_machine/guest_item.dart';
import 'package:garden/widgets/virtual_machine/repo_item.dart';
import 'package:garden/widgets/virtual_machine/cluster_summary_card.dart';
import 'package:garden/widgets/virtual_machine/power_confirm_dialog.dart';
import 'package:signals_hooks/signals_hooks.dart';

class VirtualMachine extends HookWidget {
  const VirtualMachine({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final hostLoading = useSignal(true);
    final guestLoading = useSignal(true);
    final repoLoading = useSignal(true);
    final powerLoading = useSignal<Map<String, bool>>({});
    final cluster = useSignal<dynamic>(null);
    final hosts = useSignal<List>([]);
    final guests = useSignal<List>([]);
    final repos = useSignal<List>([]);
    final currentIndex = useSignal(0);

    Future<void> getHosts() async {
      try {
        final data = await dsmVirtualizationClusterForPage('get_host');
        if (context.mounted) {
          hosts.value = data['hosts'] ?? [];
          hosts.value.sort((a, b) => a['name'].compareTo(b['name']));
        }
      } catch (e) {
        Log.warn('vm hosts: $e');
      } finally {
        if (context.mounted) hostLoading.value = false;
      }
    }
    Future<void> getGuests() async {
      try {
        final data = await dsmVirtualizationClusterForPage('get_guest');
        if (context.mounted) {
          guests.value = data['guests'] ?? [];
          guests.value.sort((a, b) => a['name'].compareTo(b['name']));
        }
      } catch (e) {
        Log.warn('vm guests: $e');
      } finally {
        if (context.mounted) guestLoading.value = false;
      }
    }
    Future<void> getRepos() async {
      try {
        final data = await dsmVirtualizationClusterForPage('get_repo');
        if (context.mounted) {
          repos.value = data['repos'] ?? [];
          repos.value.sort((a, b) => a['name'].compareTo(b['name']));
        }
      } catch (e) {
        Log.warn('vm repos: $e');
      } finally {
        if (context.mounted) repoLoading.value = false;
      }
    }
    power(guest, String action) async {
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return PowerConfirmDialog(
            action: action,
            onConfirm: () async {
              powerLoading.value = Map<String, bool>.of(powerLoading.value)
                ..[guest['id']] = true;
              try {
                await dsmVirtualizationGuestPowerActionForPage(
                    guest['id'], action);
                UiUtil.toast("请求发送成功");
                await getGuests();
              } catch (e) {
                final code = e is DSMException ? e.code : -1;
                UiUtil.toast("请求发送失败，代码：$code");
              } finally {
                powerLoading.value = Map<String, bool>.of(powerLoading.value)
                  ..[guest['id']] = false;
              }
            },
          );
        },
      );
    }

    Future<void> getData() async {
      try {
        final data = await dsmVirtualizationClusterForPage('get');
        if (context.mounted) {
          cluster.value = data;
          loading.value = false;
        }
        if (currentIndex.value == 0) {
          getHosts();
        } else if (currentIndex.value == 1) {
          getGuests();
        } else if (currentIndex.value == 2) {
          getRepos();
        }
      } catch (e) {
        Log.warn('vm cluster: $e');
        if (context.mounted) loading.value = false;
      }
    }
    Widget buildHostItem(host) {
      return HostItem(host: host);
    }

    Widget buildGuestItem(guest) {
      if (powerLoading.value[guest['id']] == null) {
        powerLoading.value[guest['id']] = false;
      }
      return GuestItem(
        guest: guest,
        powerLoading: powerLoading.value,
        onPowerAction: (action) => power(guest, action),
        onPowerOn: () async {
          powerLoading.value = Map<String, bool>.of(powerLoading.value)
            ..[guest['id']] = true;
          try {
            await dsmVirtualizationGuestCheckPowerOnForPage(guest['id']);
            await dsmVirtualizationGuestPowerActionForPage(
                guest['id'], "poweron");
            UiUtil.toast("开机请求发送成功");
            await getGuests();
          } catch (e) {
            final code = e is DSMException ? e.code : -1;
            UiUtil.toast(code == -1 ? "无法开机" : "开机请求发送失败，代码：$code");
          } finally {
            powerLoading.value = Map<String, bool>.of(powerLoading.value)
              ..[guest['id']] = false;
          }
        },
      );
    }

    Widget buildRepoItem(repo) {
      return RepoItem(repo: repo);
    }

    useEffect(() {
      getData();
      final timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        getData();
      });
      return () {
        timer.cancel();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("Virtual Machine Manager"),
      ),
      body: loading.value
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
                            totalCount: cluster.value['host_summ']['error'] +
                                cluster.value['host_summ']['healthy'] +
                                cluster.value['host_summ']['warning'],
                            errorCount: cluster.value['host_summ']['error'],
                            warningCount: cluster.value['host_summ']['warning'],
                            healthyCount: cluster.value['host_summ']['healthy'],
                            onTap: () {
                              currentIndex.value = 0;
                              getHosts();
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ClusterSummaryCard(
                            title: "虚拟机",
                            totalCount: cluster.value['guest_summ']['error'] +
                                cluster.value['guest_summ']['healthy'] +
                                cluster.value['guest_summ']['warning'],
                            errorCount: cluster.value['guest_summ']['error'],
                            warningCount:
                                cluster.value['guest_summ']['warning'],
                            healthyCount:
                                cluster.value['guest_summ']['healthy'],
                            onTap: () {
                              currentIndex.value = 1;
                              getGuests();
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ClusterSummaryCard(
                            title: "存储",
                            totalCount: cluster.value['repo_summ']['error'] +
                                cluster.value['repo_summ']['healthy'] +
                                cluster.value['repo_summ']['warning'],
                            errorCount: cluster.value['repo_summ']['error'],
                            warningCount: cluster.value['repo_summ']['warning'],
                            healthyCount: cluster.value['repo_summ']['healthy'],
                            onTap: () {
                              currentIndex.value = 2;
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
                    index: currentIndex.value,
                    children: [
                      hostLoading.value
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return buildHostItem(hosts.value[i]);
                              },
                              itemCount: hosts.value.length,
                            ),
                      guestLoading.value
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return buildGuestItem(guests.value[i]);
                              },
                              itemCount: guests.value.length,
                            ),
                      repoLoading.value
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return buildRepoItem(repos.value[i]);
                              },
                              itemCount: repos.value.length,
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
