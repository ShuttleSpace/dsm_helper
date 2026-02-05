import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class UniversalSearch extends StatefulWidget {
  const UniversalSearch({super.key});

  @override
  UniversalSearchState createState() => UniversalSearchState();
}

class UniversalSearchState extends State<UniversalSearch> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("Universal Search"),
      ),
      body: const Center(
        child: Text("待开发"),
      ),
    );
  }
}
