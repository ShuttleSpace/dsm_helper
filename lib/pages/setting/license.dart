import 'package:humphrey_garden/util/function.dart';
import 'package:humphrey_garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class License extends StatefulWidget {
  const License();

  @override
  _LicenseState createState() => _LicenseState();
}

class _LicenseState extends State<License> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("${Util.instance.appName}用户协议"),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: [
          Center(
            child: Text(
              "《${Util.instance.appName}用户协议》",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Text('''
          '''),
        ],
      ),
    );
  }
}
