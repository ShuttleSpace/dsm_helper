import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

class PowerRecoveryCard extends StatelessWidget {
  final Map powerRecovery;
  final Function(bool) onRcPowerConfigChanged;
  final Function(int, bool) onWolChanged;

  const PowerRecoveryCard({
    super.key,
    required this.powerRecovery,
    required this.onRcPowerConfigChanged,
    required this.onWolChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "电源自动恢复",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () =>
                      onRcPowerConfigChanged(!powerRecovery['rc_power_config']),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(5)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: Row(
                        children: [
                          const Text("修复电源问题后自动重新启动"),
                          const Spacer(),
                          if (powerRecovery['rc_power_config'])
                            const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppColors.primaryAction,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (powerRecovery['internal_lan_num'] != null)
                  for (int i = 1; i <= powerRecovery['internal_lan_num']; i++)
                    if (powerRecovery['wol$i'] != null) ...[
                      const SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () => onWolChanged(i, !powerRecovery['wol$i']),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(),
                              borderRadius: BorderRadius.circular(5)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text("启用局域网 $i 的局域网唤醒"),
                                const Spacer(),
                                if (powerRecovery['wol$i'])
                                  const Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color: Color(0xffff9813),
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
