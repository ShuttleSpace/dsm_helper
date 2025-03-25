import 'package:garden/pages/photos/folder.dart';
import 'package:garden/pages/photos/timeline.dart';
import 'package:flutter/material.dart';

class PhotoTab extends StatelessWidget {
  PhotoTab(this.isTeam, this.isTimeline, {this.timelineKey, this.folderKey});
  final bool isTimeline;
  final bool isTeam;
  final GlobalKey<TimelineState>? timelineKey;
  final GlobalKey<FolderState>? folderKey;
  @override
  Widget build(BuildContext context) {
    if (isTimeline) {
      return Timeline(
        isTeam,
      );
    } else {
      return Folder(
        isTeam,
      );
    }
  }
}
