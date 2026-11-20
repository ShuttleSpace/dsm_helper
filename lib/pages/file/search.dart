import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Search extends HookWidget {
  final String folder;
  const Search(this.folder, {super.key});

  @override
  Widget build(BuildContext context) {
    final folderController = useTextEditingController(text: folder);
    final folders = useListSignal<String>([folder]);
    final pattern = useSignal("");
    final searchContent = useSignal(false);

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
                  onChanged: (v) => pattern.value = v,
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
                  searchContent.value = !searchContent.value;
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
                        if (searchContent.value)
                          const Icon(
                            CupertinoIcons.checkmark_alt,
                            color: AppColors.primaryAction,
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
                  "folders": folders.value,
                  "pattern": pattern.value,
                  "search_content": searchContent.value
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
