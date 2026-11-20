import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class LedBrightnessCard extends StatelessWidget {
  final Map led;
  final Function(int) onBrightnessChanged;

  const LedBrightnessCard({
    super.key,
    required this.led,
    required this.onBrightnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "LED 亮度控制",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              height: 20,
            ),
            Slider(
              value: led['led_brightness'].toDouble(),
              onChanged: (v) => onBrightnessChanged(v.toInt()),
              min: 0,
              max: 3,
            ),
          ],
        ),
      ),
    );
  }
}
