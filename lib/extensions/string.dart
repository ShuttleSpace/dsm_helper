import 'dart:convert' as convert;
import 'dart:io';
import 'dart:math';

import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/log.dart';
import 'package:path_provider/path_provider.dart';

extension StringExt on String {
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => trim().isNotEmpty;

  Future<String?> existInTempDir() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    if (await File("$tempPath/$this").exists()) {
      return "$tempPath/$this";
    } else {
      return null;
    }
  }

  String makeUniqueFileName(String path) {
    bool unique = true;
    int num = 0;
    String uniqueName = '';
    String ext = split(".").last;
    String fullPath = "";
    while (unique) {
      if (num == 0) {
        uniqueName = this;
      } else {
        uniqueName = replaceAll(".$ext", "-$num.$ext");
      }
      fullPath = path + Platform.pathSeparator + uniqueName;
      if (File(fullPath).existsSync()) {
        Log.debug("文件存在");
        num++;
      } else {
        Log.debug("文件不存在");
        unique = false;
      }
    }
    return uniqueName;
  }

  String base64() {
    return convert.utf8.decode(convert.base64.decode(this));
  }

  String utf8() {
    return convert.utf8.encode(this).map((e) => e.toRadixString(16)).join("");
  }
}

Future<String> downloadTargetDir() async {
  if (Platform.isAndroid) {
    return settingsStore.downloadSavePath.value;
  }
  final directory = await getApplicationDocumentsDirectory();
  return "${directory.path}${Platform.pathSeparator}Download";
}

int versionCompare(String v1, String v2) {
  String buildNumber1 = '';
  String buildNumber2 = '';
  List version1 = v1.split("-");
  if (version1.length > 1) {
    buildNumber1 = version1[1];
  }
  List version2 = v2.split("-");
  if (version2.length > 1) {
    buildNumber2 = version2[1];
  }
  // 对比 build
  return int.parse(buildNumber1).compareTo(int.parse(buildNumber2));
}

/// 解析运行时间
String parseOpTime(String optime) {
  List items = optime.split(":");
  int days = int.parse(items[0]) ~/ 24;
  items[0] = (int.parse(items[0]) % 24).toString().padLeft(2, "0");
  items[1] = items[1].toString().padLeft(2, "0");
  items[2] = items[2].toString().padLeft(2, "0");
  return "${days > 0 ? "$days天" : ""} ${items.join(":")}";
}

String randStr() {
  var r = Random().nextInt(2147483646);
  return r.toString();
}
