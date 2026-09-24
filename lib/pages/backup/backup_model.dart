import 'dart:io';

import 'package:dio/dio.dart';
import 'package:garden/util/file_types.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class UploadItem {
  File? file;
  int? fileSize;
  int? uploadSize;
  UploadStatus? status;
  AssetType? type;
  DateTime? modifyTime;

  late CancelToken cancelToken;
  UploadItem(this.file, this.modifyTime, this.type,
      {this.fileSize = 0,
      this.uploadSize = 0,
      this.status = UploadStatus.wait}) {
    cancelToken = CancelToken();
  }

  @override
  String toString() {
    return 'UploadItem{modifyTime: $modifyTime}';
  }
}
