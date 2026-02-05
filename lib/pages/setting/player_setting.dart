import 'package:flutter/material.dart';
import 'package:garden/widgets/neu_back_button.dart';

class PlayerSettingPage extends StatefulWidget {
  const PlayerSettingPage({super.key});

  @override
  State<PlayerSettingPage> createState() => _PlayerSettingPageState();
}

class _PlayerSettingPageState extends State<PlayerSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text('Player Setting'),
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: () {},
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('始终使用第三方播放器'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Player Name'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
