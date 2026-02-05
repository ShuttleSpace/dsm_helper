import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class SpeedLimit extends StatefulWidget {
  const SpeedLimit({super.key});

  @override
  SpeedLimitState createState() => SpeedLimitState();
}

class SpeedLimitState extends State<SpeedLimit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("速度限制"),
      ),
      body: const Center(
        child: Text("开发中……"),
      ),
    );
  }
}
