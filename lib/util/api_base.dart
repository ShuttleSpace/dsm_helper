import 'package:garden/util/http_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';

/// API 基类
///
/// 统一管理 API 调用的基础逻辑，包括请求构建、错误处理等
///
/// 用法示例：
/// ```dart
/// class FileStationApi extends ApiBase {
///   static Future<Map> fileList(String path) async {
///     return await request(
///       api: "SYNO.FileStation.List",
///       method: "list",
///       version: 2,
///       params: {
///         "offset": 0,
///         "folder_path": path,
///         "limit": 5000,
///       },
///     );
///   }
/// }
/// ```
abstract class ApiBase {
  /// API 基础路径
  static const String _apiBaseUrl = "/webapi/";

  /// 获取 API 基础路径
  static String get apiBaseUrl => _apiBaseUrl;

  /// 执行 API 请求
  ///
  /// [api] API 名称
  /// [method] API 方法名
  /// [version] API 版本号
  /// [params] 请求参数
  /// [sid] 会话 ID，如果不提供则使用 connectionStore.sid
  /// [host] 主机地址，如果不提供则使用 connectionStore.baseUrl
  ///
  /// 返回 API 响应数据
  static Future<Map> request({
    required String api,
    required String method,
    required int version,
    Map<String, dynamic>? params,
    String? sid,
    String? host,
  }) async {
    // 构建请求数据
    Map<String, dynamic> data = {
      "api": '"$api"',
      "method": '"$method"',
      "version": version,
      "_sid": sid ?? connectionStore.sid,
    };

    // 添加额外参数
    if (params != null) {
      data.addAll(params);
    }

    // 发送请求
    return await HttpUtil.instance.post(
      "entry.cgi",
      data: data,
      host: host,
    );
  }

  /// 执行 GET 请求
  ///
  /// [path] 请求路径
  /// [data] 请求参数
  /// [sid] 会话 ID
  /// [host] 主机地址
  static Future<Map> get({
    required String path,
    Map<String, dynamic>? data,
    String? sid,
    String? host,
  }) async {
    return await HttpUtil.instance.get(
      path,
      data: data,
      host: host,
    );
  }

  /// 执行 POST 请求
  ///
  /// [path] 请求路径
  /// [data] 请求参数
  /// [sid] 会话 ID
  /// [host] 主机地址
  static Future<Map> post({
    required String path,
    Map<String, dynamic>? data,
    String? sid,
    String? host,
  }) async {
    return await HttpUtil.instance.post(
      path,
      data: data,
      host: host,
    );
  }

  /// 检查 API 响应是否成功
  ///
  /// [response] API 响应数据
  ///
  /// 返回 true 表示成功，false 表示失败
  static bool isSuccess(Map response) {
    return response['success'] == true;
  }

  /// 获取 API 响应错误代码
  ///
  /// [response] API 响应数据
  static int? getErrorCode(Map response) {
    final error = response['error'];
    if (error is Map) {
      return int.tryParse(error['code']);
    }
    return null;
  }

  /// 获取 API 响应错误消息
  ///
  /// [response] API 响应数据
  static String? getErrorMessage(Map response) {
    final error = response['error'];
    if (error is Map) {
      return error['errors']?.toString() ?? error.toString();
    }
    return null;
  }

  /// 处理 API 响应
  ///
  /// [response] API 响应数据
  /// [showToast] 是否显示错误提示，默认为 true
  ///
  /// 返回处理后的数据，如果失败则返回 null
  static Map? handleResponse(
    Map? response, {
    bool showToast = true,
  }) {
    if (response == null) {
      if (showToast) {
        UiUtil.toast("请求失败");
      }
      return null;
    }

    if (!isSuccess(response)) {
      final errorCode = getErrorCode(response);
      final errorMessage = getErrorMessage(response);
      if (showToast) {
        UiUtil.toast("操作失败: ${errorMessage ?? errorCode ?? '未知错误'}");
      }
      return null;
    }

    return response;
  }
}

/// API 版本管理
///
/// 统一管理各 API 的版本号
class ApiVersions {
  ApiVersions._();

  // ==================== FileStation ====================
  static const int fileStationList = 2;
  static const int fileStationUpload = 2;
  static const int fileStationDelete = 2;
  static const int fileStationRename = 2;
  static const int fileStationCopyMove = 2;
  static const int fileStationCreateFolder = 2;
  static const int fileStationSearch = 2;
  static const int fileStationShare = 3;

  // ==================== Auth ====================
  static const int authLogin = 4;
  static const int authLogout = 1;

  // ==================== Photo/Foto ====================
  static const int photoBrowseAlbum = 1;
  static const int photoBrowseFolder = 1;
  static const int photoBrowseItem = 1;
  static const int photoGetInfo = 1;

  // ==================== Download Station ====================
  static const int downloadStationTask = 2;
  static const int downloadStationList = 1;

  // ==================== Docker ====================
  static const int dockerContainer = 1;
  static const int dockerImage = 1;

  // ==================== Control Panel ====================
  static const int controlPanelNetwork = 1;
  static const int controlPanelPower = 1;
  static const int controlPanelTerminal = 2;

  // ==================== Virtualization ====================
  static const int virtualizationTask = 1;
  static const int virtualizationNetwork = 1;
}
