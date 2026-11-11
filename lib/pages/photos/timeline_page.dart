import 'package:garden/pages/photos/timeline.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({
    super.key,
    this.title,
    this.type,
    this.geocodingId = 0,
    this.generalTagId = 0,
    this.isTeam = false,
    this.recentlyAdd = false,
  });
  final String? title;
  final String? type;
  final int geocodingId;
  final bool isTeam;
  final int generalTagId;
  final bool recentlyAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title ?? ''),
      ),
      body: Timeline(
        isTeam,
        type: type ?? '',
        geocodingId: geocodingId,
        generalTagId: generalTagId,
        recentlyAdd: recentlyAdd,
      ),
    );
  }
}
