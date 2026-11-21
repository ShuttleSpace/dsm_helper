import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class ISCSIManger extends StatelessWidget {
  const ISCSIManger({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("iSCSI Manager"),
      ),
      body: const Center(
        child: Text("待开发"),
      ),
    );
  }
}
