import 'package:garden/pages/photos/folder.dart';
import 'package:garden/pages/photos/timeline.dart';
import 'package:flutter/material.dart';

class PhotoTab extends StatelessWidget {
  const PhotoTab(this.isTeam, this.isTimeline, {super.key});
  final bool isTimeline;
  final bool isTeam;
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
