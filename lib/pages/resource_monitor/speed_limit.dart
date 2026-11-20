import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class SpeedLimit extends StatelessWidget {
  const SpeedLimit({super.key});

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
