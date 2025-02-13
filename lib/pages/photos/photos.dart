import 'package:dsm_helper/pages/photos/album_tab.dart';
import 'package:dsm_helper/pages/photos/folder.dart';
import 'package:dsm_helper/pages/photos/photo_tab.dart';
import 'package:dsm_helper/pages/photos/share_tab.dart';
import 'package:dsm_helper/pages/photos/timeline.dart';
import 'package:dsm_helper/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Photos extends StatefulWidget {
  const Photos();

  @override
  State<Photos> createState() => _PhotosState();
}

class _PhotosState extends State<Photos> {
  int currentIndex = 0;
  bool isTeam = false;
  bool isTimeline = true;
  GlobalKey<TimelineState> timelineKey = GlobalKey();
  GlobalKey<FolderState> folderKey = GlobalKey();
  GlobalKey<AlbumTabState> albumTabKey = GlobalKey();
  @override
  void initState() {
    // 获取
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: DropdownMenu(
          initialSelection: currentIndex,
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 0, label: '图片'),
            DropdownMenuEntry(value: 1, label: '相册'),
            DropdownMenuEntry(value: 2, label: '共享'),
          ],
          onSelected: (value) {
            setState(() {
              currentIndex = value ?? 0;
            });
          },
        ),
        actions: [
          if (currentIndex != 2)
            Padding(
              padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      return Material(
                        color: Colors.transparent,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(),
                              borderRadius: BorderRadius.circular(5)),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.all(22),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  OutlinedButton(
                                    onPressed: () async {
                                      setState(() {
                                        isTeam = !isTeam;
                                      });
                                      if (isTimeline) {
                                        timelineKey.currentState
                                            ?.getData(isTeam: isTeam);
                                      } else {
                                        folderKey.currentState
                                            ?.getData(isTeam: isTeam);
                                      }
                                      albumTabKey.currentState
                                          ?.getData(isTeam: isTeam);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      "切换到${isTeam ? '个人空间' : '共享空间'}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 16,
                                  ),
                                  if (currentIndex == 0) ...[
                                    OutlinedButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          isTimeline = !isTimeline;
                                        });
                                        if (isTimeline) {
                                          timelineKey.currentState
                                              ?.getData(isTeam: isTeam);
                                        } else {
                                          folderKey.currentState
                                              ?.getData(isTeam: isTeam);
                                        }
                                      },
                                      child: Text(
                                        "切换到${isTimeline ? '文件夹' : '时间线'}视图",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 16,
                                    ),
                                  ],
                                  OutlinedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      "取消",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                ],
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
              index: currentIndex,
              children: [
                PhotoTab(
                  isTeam,
                  isTimeline,
                  timelineKey: timelineKey,
                  folderKey: folderKey,
                ),
                AlbumTab(
                  isTeam,
                ),
                ShareTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
