import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/pages/file/select_folder.dart';

/// 共享的文件夹选择器浮层。
///
/// 文件页的「移动到/复制到」、备份页的「选择备份目的地」等都使用同一结构，
/// 这里统一容器样式，业务侧只消费返回的目录列表。
Future<dynamic> showFolderPickerSheet(
  BuildContext context, {
  ImageFilter? filter,
}) {
  return showCupertinoModalPopup(
    context: context,
    filter: filter,
    builder: (context) => SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const SelectFolder(multi: false),
        ),
      ),
    ),
  );
}
