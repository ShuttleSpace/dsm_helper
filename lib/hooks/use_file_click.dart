import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/pages/common/office_preview.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/util/ui_util.dart';

typedef OpenExternallyFn = Future<void> Function(Map file);

/// 本地原生预览不支持的格式：
/// - docx/xlsx/xls → 内嵌 JS 的 WebView 预览
/// - 其余 → 系统"打开方式"选择器
///
/// 文件夹进入下一级、多选、以及已有原生预览仍由调用方的 openFile 处理；
/// 长按弹出我们自己的操作面板（fileAction）也不在这里。
OpenExternallyFn useOpenExternally(BuildContext context) {
  return (Map file) async {
    final name = file['name'] as String;
    final url = fileContentUrl(file);

    if (canWebPreview(name)) {
      if (!context.mounted) return;
      await Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => OfficePreviewPage(file: file, url: url),
      ));
      return;
    }

    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: url,
        type: _mimeType(fileExtension(name)),
        arguments: const {},
      );
      try {
        await intent.launchChooser('选择打开方式');
      } catch (e) {
        UiUtil.toast('无法调用系统打开方式：$e');
      }
    } else {
      UiUtil.toast('暂不支持预览该格式，请下载后打开');
    }
  };
}

String _mimeType(String ext) {
  switch (ext) {
    case 'torrent':
      return 'application/x-bittorrent';
    case 'iso':
    case 'img':
      return 'application/x-iso9660-image';
    case 'zip':
      return 'application/zip';
    case 'apk':
      return 'application/vnd.android.package-archive';
    case 'doc':
      return 'application/msword';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'csv':
      return 'text/csv';
    default:
      return '*/*';
  }
}
