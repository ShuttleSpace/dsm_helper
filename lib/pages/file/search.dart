import 'package:dsm_helper/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  final String folder;
  Search(this.folder);
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController folderController = TextEditingController();
  List<String> folders = [];
  String pattern = "";
  bool recursive = true;
  bool searchContent = false;

  @override
  void initState() {
    setState(() {
      folders.add(widget.folder);
      folderController.value = TextEditingValue(text: widget.folder);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("搜索文件"),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(5)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (v) => pattern = v,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: '关键字',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    searchContent = !searchContent;
                  });
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text("启用文件内容搜索"),
                        Spacer(),
                        if (searchContent)
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Color(0xffff9813),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(5)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: folderController,
                  enabled: false,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: '所在位置',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  "folders": folders,
                  "pattern": pattern,
                  "search_content": searchContent
                });
                // Navigator.of(context).push(CupertinoPageRoute(
                //     builder: (context) {
                //       return SearchResult(
                //         folders,
                //         pattern,
                //         searchContent: searchContent,
                //       );
                //     },
                //     settings: RouteSettings(name: "search_result")));
              },
              child: Text(
                ' 搜索 ',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
