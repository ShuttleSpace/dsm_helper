import 'package:dsm_helper/util/function.dart';
import 'package:dsm_helper/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class Feedback extends StatefulWidget {
  const Feedback();

  @override
  _FeedbackState createState() => _FeedbackState();
}

class _FeedbackState extends State<Feedback> {
  String content = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("问题反馈"),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (v) => content = v,
                maxLines: 5,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: '请输入反馈内容',
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          OutlinedButton(
              onPressed: () {
                Util.toast("感谢您的反馈");
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "提交",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
