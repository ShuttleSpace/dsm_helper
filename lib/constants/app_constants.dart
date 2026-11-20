import 'package:garden/stores/connection_store.dart';

/// 应用常量
///
/// 统一管理应用中使用的各种常量
class AppConstants {
  AppConstants._();

  // ==================== 布局常量 ====================

  /// 小间距
  static const double paddingSmall = 8.0;

  /// 中间距
  static const double paddingMedium = 16.0;

  /// 大间距
  static const double paddingLarge = 20.0;

  /// 超大间距
  static const double paddingXLarge = 24.0;

  // ==================== 字体大小 ====================

  /// 小字体
  static const double fontSizeSmall = 12.0;

  /// 中小字体
  static const double fontSizeMedium = 14.0;

  /// 大字体
  static const double fontSizeLarge = 16.0;

  /// 超大字体
  static const double fontSizeXLarge = 18.0;

  /// 特大字体
  static const double fontSizeXXLarge = 20.0;

  // ==================== 圆角半径 ====================

  /// 小圆角
  static const double borderRadiusSmall = 8.0;

  /// 中圆角
  static const double borderRadiusMedium = 12.0;

  /// 大圆角
  static const double borderRadiusLarge = 18.0;

  // ==================== 图标大小 ====================

  /// 小图标
  static const double iconSizeSmall = 16.0;

  /// 中图标
  static const double iconSizeMedium = 24.0;

  /// 大图标
  static const double iconSizeLarge = 32.0;

  // ==================== 卡片样式 ====================

  /// 卡片外边距
  static const double cardMargin = 20.0;

  /// 卡片内边距
  static const double cardPadding = 20.0;

  /// 卡片圆角
  static const double cardBorderRadius = 18.0;

  /// 卡片边框宽度
  static const double cardBorderWidth = 1.0;

  // ==================== 按钮样式 ====================

  /// 按钮内边距
  static const double buttonPaddingHorizontal = 16.0;
  static const double buttonPaddingVertical = 12.0;

  /// 按钮间距
  static const double buttonSpacing = 16.0;

  // ==================== 对话框样式 ====================

  /// 对话框内边距
  static const double dialogPadding = 20.0;

  /// 对话框标题字体大小
  static const double dialogTitleFontSize = 20.0;

  /// 对话框内容字体大小
  static const double dialogContentFontSize = 20.0;

  /// 对话框按钮字体大小
  static const double dialogButtonFontSize = 18.0;

  /// 对话框圆角
  static const double dialogBorderRadius = 18.0;

  // ==================== 列表样式 ====================

  /// 列表项内边距
  static const double listItemPadding = 16.0;

  /// 列表项高度
  static const double listItemHeight = 56.0;

  // ==================== 动画时长 ====================

  /// 短动画时长
  static const Duration animationShort = Duration(milliseconds: 200);

  /// 中动画时长
  static const Duration animationMedium = Duration(milliseconds: 300);

  /// 长动画时长
  static const Duration animationLong = Duration(milliseconds: 500);

  // ==================== API 常量 ====================

  /// 默认分页限制
  static const int defaultLimit = 5000;

  /// 默认超时时间（秒）
  static const int defaultTimeout = 20;

  /// API 基础路径
  static const String apiBaseUrl = "/webapi/";

  /// API 默认版本
  static const int apiDefaultVersion = 1;

  // ==================== 文件相关常量 ====================

  /// 默认文件名长度
  static const int defaultFileNameLength = 255;

  /// 支持的图片格式
  static const List<String> supportedImageFormats = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'ico',
    'tiff',
    'tif',
    'webp'
  ];

  /// 支持的视频格式
  static const List<String> supportedVideoFormats = [
    'mp4',
    'avi',
    'mkv',
    'mov',
    'flv',
    'wmv',
    'webm',
    '3gp',
    'm4v'
  ];

  /// 支持的音频格式
  static const List<String> supportedAudioFormats = [
    'mp3',
    'wav',
    'flac',
    'aac',
    'm4a',
    'ogg',
    'wma'
  ];

  // ==================== 表单常量 ====================

  /// 最小密码长度
  static const int minPasswordLength = 6;

  /// 最大密码长度
  static const int maxPasswordLength = 128;

  /// 默认用户名长度
  static const int defaultUsernameLength = 32;

  // ==================== 缓存常量 ====================

  /// 默认缓存时间（秒）
  static const int defaultCacheDuration = 300;

  /// 图片缓存大小（MB）
  static const int imageCacheSize = 100;

  // ==================== 分页常量 ====================

  /// 默认每页数量
  static const int defaultPageSize = 20;

  /// 最大每页数量
  static const int maxPageSize = 100;

  // ==================== 上传相关 ====================

  /// 最大上传文件大小（MB）
  static const int maxUploadFileSize = 1024;

  /// 默认上传分块大小（MB）
  static const int defaultUploadChunkSize = 5;

  // ==================== 下载相关 ====================

  /// 最大同时下载数
  static const int maxConcurrentDownloads = 3;

  /// 默认下载超时时间（秒）
  static const int downloadTimeout = 60;

  // ==================== 正则表达式 ====================

  /// 邮箱正则表达式
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// IP 地址正则表达式
  static const String ipRegex =
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';

  /// URL 正则表达式
  static const String urlRegex = r'^https?://[^\s/$.?#].[^\s]*$';

  // ==================== 其他常量 ====================

  /// 应用名称
  static const String appName = "DSM花园";

  /// 默认语言
  static const String defaultLanguage = "zh_CN";

  /// DSM 版本 6
  static const int dsmVersion6 = 6;

  /// DSM 版本 7
  static const int dsmVersion7 = 7;

  /// 最小支持的 DSM 版本
  static const int minDsmVersion = 6;

  /// 最大支持的 DSM 版本
  static const int maxDsmVersion = 7;

  static final String wallpaper =
      "${connectionStore.baseUri}/webapi/entry.cgi?api=SYNO.Core.PersonalSettings&method=wallpaper&version=1&path=%22%22&retina=true&_sid=${connectionStore.sid}";
}
