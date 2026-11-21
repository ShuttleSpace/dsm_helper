import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class MonitorSetting extends StatelessWidget {
  const MonitorSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("设置"),
      ),
      body: const Center(
        child: Text("开发中……"),
      ),
    );
  }
}
