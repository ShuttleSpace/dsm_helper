import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class ISCSIManger extends StatefulWidget {
  const ISCSIManger({super.key});

  @override
  ISCSIMangerState createState() => ISCSIMangerState();
}

class ISCSIMangerState extends State<ISCSIManger> {
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
