import 'dart:io';

import 'package:cool_ui/cool_ui.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<Map> saveImage(String url,
    {required BuildContext context, bool showLoading = true}) async {
  HideCallback? hide;
  try {
    bool permission = false;
    if (Platform.isAndroid) {
      permission = await Permission.storage.request().isGranted;
      Log.info(permission);
    } else {
      permission = await Permission.photos.request().isGranted;
    }
    if (!permission) {
      return {
        "code": 2,
        "msg": "permission",
      };
    }
    if (showLoading && context.mounted) {
      hide = showWeuiLoadingToast(context: context, message: const Text("保存中"));
    }
    File? save;
    if (url.startsWith("http")) {
      File? image = await getCachedImageFile(url);
      save = await image
          ?.copy("${image.path}${DateTime.now().millisecondsSinceEpoch}.png");
    } else {
      save = File(url);
    }
    if (save != null) {
      final result = await ImageGallerySaverPlus.saveImage(
        save.readAsBytesSync(),
        name: connectionStore.appName.value,
      );
      // ImageGallerySaverPlus 返回的是一个 Map 或 List
      if (result is Map && result['isSuccess'] == true) {
        return {
          "code": 1,
          "msg": "success",
        };
      } else if (result is List && result.isNotEmpty) {
        return {
          "code": 1,
          "msg": "success",
        };
      } else {
        return {
          "code": 0,
          "msg": "error",
        };
      }
    } else {
      UiUtil.toast('获取缓存文件失败!');
      hide?.call();
      return {
        "code": 0,
        "msg": "error",
      };
    }
  } catch (e) {
    hide?.call();
    return {
      "code": 0,
      "msg": "error",
    };
  }
}
