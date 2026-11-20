import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class BeepControlCard extends StatelessWidget {
  final Map beepControl;
  final Function(String, bool) onBeepOptionChanged;

  const BeepControlCard({
    super.key,
    required this.beepControl,
    required this.onBeepOptionChanged,
  });

  Widget _buildBeepOption(String title, String key) {
    if (beepControl['support_$key'] != null && beepControl['support_$key']) {
      return Column(
        children: [
          GestureDetector(
            onTap: () => onBeepOptionChanged(key, !beepControl[key]),
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(5)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(title),
                    const Spacer(),
                    if (beepControl[key])
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
          const SizedBox(
            height: 20,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

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
              "哔声控制",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBeepOption("冷却风扇故障", "fan_fail"),
                _buildBeepOption("存储空间降级或毁损", "volume_crash"),
                _buildBeepOption("存储空间或 SSD 缓存异常", "volume_or_cache_crash"),
                _buildBeepOption("SSD 缓存异常", "ssd_cache_crash"),
                _buildBeepOption("系统开机", "poweron_beep"),
                _buildBeepOption("按下电源按钮后系统关机", "poweroff_beep"),
                _buildBeepOption("冗余电源离线", "redundant_power_fail"),
                _buildBeepOption("系统重置", "reset_beep"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
