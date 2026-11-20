
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:garden/widgets/dashboard/dashboard_card_parts.dart';

class DashboardRecentLogCard extends HookWidget {
  const DashboardRecentLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    final recentLogs = useListSignal([]);
    final error = useSignal('');

    fetchData() {
      dsmCoreSyslogClientLogList(
              logtype: 'ftp,filestation,webdav,cifs,tftp,afp',
              target: 'LOCAL',
              sortDirection: 'desc',
              limit: 50,
              offset: 0)
          .then((res) {
        recentLogs.value = res['items'] as List;
      }).catchError((e) {
        error.value = e.toString();
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const LogCenter();
            },
            settings: const RouteSettings(name: "log_center")));
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/log.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "最新日志",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const DashboardCardItemCollapse("RecentLog")
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Builder(builder: (context) {
                if (recentLogs.watch(context).isEmpty) {
                  return TextButton(
                      onPressed: fetchData,
                      child: Text.rich(TextSpan(
                          text: error.isEmpty ? '暂无日志' : error.value,
                          children: [
                            TextSpan(
                                text: '\t\t点击重试',
                                style: dashboardRetryTextStyle(context))
                          ])));
                }
                if (context.isCardItemCollapsed('RecentLog')) {
                  return CupertinoScrollbar(
                    child: ListView.builder(
                      itemCount: recentLogs.length,
                      itemBuilder: (context, i) {
                        return Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(),
                              borderRadius: BorderRadius.circular(18)),
                          clipBehavior: Clip.hardEdge,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              maxLines: 3,
                              "${recentLogs.value[i]?['msg'] ?? ''}",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

