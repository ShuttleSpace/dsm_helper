import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class Search extends StatefulWidget {
  final String folder;
  const Search(this.folder, {super.key});
  @override
  SearchState createState() => SearchState();
}

class SearchState extends State<Search> {
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
        title: const Text("搜索文件"),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  onChanged: (v) => pattern = v,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: '关键字',
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    searchContent = !searchContent;
                  });
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: Row(
                      children: [
                        const Text("启用文件内容搜索"),
                        const Spacer(),
                        if (searchContent)
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  controller: folderController,
                  enabled: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: '所在位置',
                  ),
                ),
              ),
            ),
            const SizedBox(
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
              child: const Text(
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
