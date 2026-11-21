import 'file_types.dart';

/// 文件类型工具类
/// 
/// 提供文件类型判断的静态方法
class FileTypeUtil {
  FileTypeUtil._();
  
  /// 文件类型枚举
  static const List<String> imageExtensions = [
    "png", "jpg", "jpeg", "gif", "bmp", "ico", "tiff", "tif", "webp"
  ];
  
  static const List<String> movieExtensions = [
    "3gp", "3g2", "asf", "dat", "divx", "dvr-ms", "m2t", "m2ts", "m4v",
    "mkv", "mp4", "mts", "mov", "qt", "tp", "trp", "ts", "vob", "wmv",
    "xvid", "ac3", "amr", "rm", "rmvb", "ifo", "mpeg", "mpg", "mpe",
    "m1v", "m2v", "mpeg1", "mpeg2", "mpeg4", "ogv", "webm", "flv", "avi",
    "swf", "f4v"
  ];
  
  static const List<String> musicExtensions = [
    "mp3", "wma", "wav", "mid", "midi", "ape", "flac", "aac", "m4a", "ogg"
  ];
  
  static const List<String> subtitleExtensions = ["srt", "ass", "ssa", "vtt", "sub"];

  static const List<String> psExtensions = ["psd", "ai", "eps"];
  
  static const List<String> htmlExtensions = ["html", "htm", "xml", "json"];
  
  static const List<String> wordExtensions = ["doc", "docx"];
  
  static const List<String> pptExtensions = ["ppt", "pptx"];
  
  static const List<String> excelExtensions = ["xls", "xlsx", "csv"];
  
  static const List<String> textExtensions = ["txt", "md", "log", "ini", "conf"];
  
  static const List<String> zipExtensions = [
    "zip", "rar", "7z", "tar", "gz", "bz2", "xz"
  ];
  
  static const List<String> codeExtensions = [
    "java", "py", "js", "ts", "html", "css", "php", "rb", "go", "rs", "cpp",
    "c", "h", "swift", "kt", "dart", "lua", "sql", "sh", "bat"
  ];
  
  static const List<String> pdfExtensions = ["pdf"];
  
  static const List<String> apkExtensions = ["apk", "aab", "ipa"];
  
  static const List<String> isoExtensions = ["iso", "img", "dmg", "vmdk"];
  
  /// 判断文件类型
  static String getFileType(String fileName) {
    if (fileName.contains('.')) {
      String extension = fileName.split('.').last.toLowerCase();
      
      if (imageExtensions.contains(extension)) return 'image';
      if (movieExtensions.contains(extension)) return 'movie';
      if (musicExtensions.contains(extension)) return 'music';
      if (psExtensions.contains(extension)) return 'ps';
      if (htmlExtensions.contains(extension)) return 'html';
      if (wordExtensions.contains(extension)) return 'word';
      if (pptExtensions.contains(extension)) return 'ppt';
      if (excelExtensions.contains(extension)) return 'excel';
      if (textExtensions.contains(extension)) return 'text';
      if (zipExtensions.contains(extension)) return 'zip';
      if (codeExtensions.contains(extension)) return 'code';
      if (pdfExtensions.contains(extension)) return 'pdf';
      if (apkExtensions.contains(extension)) return 'apk';
      if (isoExtensions.contains(extension)) return 'iso';
    }
    return 'other';
  }
  
  /// 判断是否为图片
  static bool isImage(String fileName) {
    return getFileType(fileName) == 'image';
  }
  
  /// 判断是否为视频
  static bool isVideo(String fileName) {
    return getFileType(fileName) == 'movie';
  }
  
  /// 判断是否为音频
  static bool isAudio(String fileName) {
    return getFileType(fileName) == 'music';
  }

  /// 视频的同名字幕旁车文件：`movie.srt`、`movie.zh.ass` 都算。
  static List<String> findSiblingSubtitles(List files, String baseName) {
    final prefix = '${baseName.toLowerCase()}.';
    final result = <String>[];
    for (final e in files) {
      final name = (e['name'] as String?)?.toLowerCase();
      if (name == null || !name.startsWith(prefix)) continue;
      if (subtitleExtensions.contains(name.split('.').last)) {
        result.add(e['path'] as String);
      }
    }
    return result;
  }
  
  /// 判断是否为压缩包
  static bool isArchive(String fileName) {
    return getFileType(fileName) == 'zip';
  }
  
  /// 获取文件图标名称
  static String getIconName(String fileName) {
    return '${getFileType(fileName)}.png';
  }

  /// 将字符串类型转换为 FileTypeEnum
  static FileTypeEnum toFileTypeEnum(String type) {
    switch (type) {
      case 'folder': return FileTypeEnum.folder;
      case 'image': return FileTypeEnum.image;
      case 'movie': return FileTypeEnum.movie;
      case 'music': return FileTypeEnum.music;
      case 'ps': return FileTypeEnum.ps;
      case 'html': return FileTypeEnum.html;
      case 'word': return FileTypeEnum.word;
      case 'ppt': return FileTypeEnum.ppt;
      case 'excel': return FileTypeEnum.excel;
      case 'text': return FileTypeEnum.text;
      case 'zip': return FileTypeEnum.zip;
      case 'code': return FileTypeEnum.code;
      case 'pdf': return FileTypeEnum.pdf;
      case 'apk': return FileTypeEnum.apk;
      case 'iso': return FileTypeEnum.iso;
      default: return FileTypeEnum.other;
    }
  }
}