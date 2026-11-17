import 'package:garden/pages/photos/album_tab.dart';
import 'package:garden/pages/photos/photo_tab.dart';
import 'package:garden/pages/photos/share_tab.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Photos extends HookWidget {
  const Photos({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = useSignal(0);
    final isTeam = useSignal(false);
    final isTimeline = useSignal(true);
    final menuW = MediaQuery.sizeOf(context).width / 5;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: DropdownMenu(
          width: menuW,
          initialSelection: currentIndex.value,
          enableSearch: false,
          enableFilter: false,
          textAlign: TextAlign.center,
          textStyle: const TextStyle(fontSize: 12),
          inputDecorationTheme:
              const InputDecorationTheme(border: InputBorder.none),
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 0, label: '图片'),
            DropdownMenuEntry(value: 1, label: '相册'),
            DropdownMenuEntry(value: 2, label: '共享'),
          ],
          onSelected: (value) {
            currentIndex.value = value ?? 0;
          },
        ),
        actions: [
          if (currentIndex.value != 2)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      return SizedBox(
                        width: double.infinity,
                        child: Material(
                        color: Colors.transparent,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(),
                              borderRadius: BorderRadius.circular(18)),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  OutlinedButton(
                                    onPressed: () async {
                                      isTeam.value = !isTeam.value;
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      "切换到${isTeam.value ? '个人空间' : '共享空间'}",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  if (currentIndex.value == 0) ...[
                                    OutlinedButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        isTimeline.value = !isTimeline.value;
                                      },
                                      child: Text(
                                        "切换到${isTimeline.value ? '文件夹' : '时间线'}视图",
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                  ],
                                  OutlinedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      "取消",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                  );
                },
                child: Image.asset(
                  "assets/icons/actions.png",
                  width: 20,
                  height: 20,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: currentIndex.value,
              children: [
                PhotoTab(
                  isTeam.value,
                  isTimeline.value,
                ),
                AlbumTab(
                  isTeam.value,
                ),
                const ShareTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
