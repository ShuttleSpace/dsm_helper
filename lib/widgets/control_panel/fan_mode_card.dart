import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class FanModeCard extends StatelessWidget {
  final Map fanSpeed;
  final Function(String) onFanModeChanged;

  const FanModeCard({
    super.key,
    required this.fanSpeed,
    required this.onFanModeChanged,
  });

  Widget _buildFanModeOption(
    String title,
    String description,
    String modeValue,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onFanModeChanged(modeValue),
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title),
                        Text(
                          description,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 22,
                    child: fanSpeed['dual_fan_speed'] == modeValue
                        ? const Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Color(0xffff9813),
                            size: 22,
                          )
                        : null,
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
              "风扇模式",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFanModeOption(
                  "全速模式",
                  "风扇以全速工作可保持系统冷却，但会产生较大的噪音。",
                  "fullfan",
                ),
                _buildFanModeOption(
                  "低温模式",
                  "风扇以较高的速度工作可保持系统冷却，但会产生较大的噪音。",
                  "coolfan",
                ),
                _buildFanModeOption(
                  "静音模式",
                  "风扇以较低的速度工作所产生的噪音较低，但过程中系统可能会变热。",
                  "quietfan",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
