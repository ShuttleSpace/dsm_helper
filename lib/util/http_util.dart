import 'dart:convert';
import 'package:garden/stores/connection_store.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/storage_util.dart';
import 'package:path_provider/path_provider.dart';

export 'package:garden/extensions/datetime.dart';
export 'package:garden/extensions/int.dart';
export 'package:garden/extensions/string.dart';

export 'file_types.dart';

final _httpClient = HttpClient();

extension DioExtension on Dio {
  /// proxy  "PROXY host:port; PROXY host2:port2; DIRECT"
  /// browser PAC (proxy auto-config) scripts.
  _createHttpClient({BadCertificateCallback? callback, String? proxy}) {
    if (httpClientAdapter is IOHttpClientAdapter) {
      (httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        if (callback != null) {
          _httpClient.badCertificateCallback = callback;
        }
        if (proxy != null) {
          _httpClient.findProxy = (uri) {
            return proxy;
          };
        }
        return _httpClient;
      };
    } else {
      Log.warn(
          "DioExtension.badCertificateCallback: httpClientAdapter is not IOHttpClientAdapter");
    }
  }
}
// FileTypeEnum 和 UploadStatus 已移至 file_types.dart

/// HTTP 请求工具类
///
/// 提供网络请求相关的静态方法
class HttpUtil {
  HttpUtil._internal();
  factory HttpUtil() => _instance;
  static final HttpUtil _instance = HttpUtil._internal();
  static HttpUtil get instance => _instance;

  Future<dynamic> get(String url,
      {Map<String, dynamic>? data,
      bool login = true,
      String? host,
      Map<String, dynamic>? headers,
      CancelToken? cancelToken,
      bool? checkSsl,
      String? cookie,
      int timeout = 20,
      bool decode = true}) async {
    headers = headers ?? {};
    headers['Cookie'] = cookie ?? connectionStore.cookie;
    headers["Accept-Language"] =
        "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,zh-TW;q=0.5";
    headers['origin'] = host ?? connectionStore.baseUri;
    headers['referer'] = host ?? connectionStore.baseUri;
    Dio dio = Dio(
      BaseOptions(
        baseUrl: url.startsWith("http")
            ? ""
            : ("${host ?? connectionStore.baseUri}/webapi/"),
        headers: headers,
        connectTimeout: Duration(seconds: timeout),
      ),
    );
    dio._createHttpClient(
        callback: (cert, host, port) {
          return !(checkSsl ?? connectionStore.checkSsl.value);
        },
        proxy: 'PROXY 192.168.1.73:8899; PROXY 127.0.0.1:8899; DIRECT');

    Response response;
    try {
      // Log.debug(
      //     "curl: '${connectionStore.baseUri}/$url' ${data?.entries.map((e) => '-d "${e.key}=${e.value}"').join(' ')}");
      response =
          await dio.get(url, queryParameters: data, cancelToken: cancelToken);
      if (url == "auth.cgi") {
        if (response.headers.map['set-cookie'] != null &&
            response.headers.map['set-cookie']!.isNotEmpty) {
          List cookies = [];
          //从原始cookie中提取did
          String did = "";
          if (connectionStore.cookie.value != '') {
            List originCookies = connectionStore.cookie.value.split("; ");
            for (int i = 0; i < originCookies.length; i++) {
              Cookie cookie = Cookie.fromSetCookieValue(originCookies[i]);
              if (cookie.name == "did") {
                did = cookie.value;
              }
            }
          }
          bool haveDid = false;
          for (int i = 0; i < response.headers.map['set-cookie']!.length; i++) {
            Cookie cookie = Cookie.fromSetCookieValue(
                response.headers.map['set-cookie']![i]);
            cookies.add("${cookie.name}=${cookie.value}");
            if (cookie.name == "did") {
              haveDid = true;
            }
          }
          //如果新cookie中不含did
          if (!haveDid && did != "") {
            cookies.add("did=$did");
          }

          connectionStore.setCookie(cookies.join("; "));
          await StorageUtil.setString("smid", connectionStore.cookie.value);
        }
      }

      if (response.data is String && decode) {
        try {
          return json.decode(response.data);
        } catch (e) {
          return response.data;
        }
      } else if (response.data is Map) {
        return response.data;
      } else {
        return response.data;
      }
    } on DioException catch (error) {
      String code = "";
      if (error.message != null &&
          error.message!.contains("CERTIFICATE_VERIFY_FAILED")) {
        code = "SSL/HTTPS证书有误";
      } else {
        code = error.message ?? '';
      }
      Log.info("请求出错:${headers['origin']} $url ${error.toString()}");
      return {
        "success": false,
        "error": {"code": code},
        "data": null
      };
    } catch (e) {
      Log.error("get $url 出错:$e");
    }
  }

  Future<dynamic> post(String url,
      {Map<String, dynamic>? data,
      bool login = true,
      String? host,
      CancelToken? cancelToken,
      Map<String, dynamic>? headers,
      bool? checkSsl,
      String? cookie,
      int timeout = 20}) async {
    headers = headers ?? {};
    headers['Cookie'] = cookie ?? connectionStore.cookie;
    headers["Accept-Language"] =
        "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,zh-TW;q=0.5";
    headers['origin'] = host ?? connectionStore.baseUri;
    headers['referer'] = host ?? connectionStore.baseUri;
    Dio dio = Dio(
      BaseOptions(
        // connectTimeout: timeout,
        baseUrl: "${host ?? connectionStore.baseUri}/webapi/",
        contentType: "application/x-www-form-urlencoded",
        headers: headers,
      ),
    );
    // TODO: support proxy
    //忽略Https校验
    // TODO: switch -> https validate checker
    dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      request: false,
      requestBody: false,
      responseBody: false,
      responseHeader: false,
      logPrint: Log.debug,
    ));
    dio._createHttpClient(
        callback: (cert, host, port) {
          return !(checkSsl ?? connectionStore.checkSsl.value);
        },
        proxy: 'PROXY 192.168.1.73:8899; PROXY 127.0.0.1:8899; DIRECT');
    Response response;
    try {
      // Log.debug(
      //     "curl: '${connectionStore.baseUri}/$url' ${data?.entries.map((e) => '-d "${e.key}=${e.value}"').join(' ')}");
      response = await dio.post(url, data: data, cancelToken: cancelToken);
      return response.data;
    } on DioException catch (error) {
      Log.error("请求出错:${headers['origin']} $url \n请求内容:$data\n 错误原因: $error");
      return {
        "success": false,
        "error": {"code": error.message},
        "data": null
      };
    } catch (e) {
      Log.error("post $url 出错:$e");
    }
  }

  Future<dynamic> upload(String url,
      {Map<String, dynamic>? params,
      required Map<String, dynamic> data,
      bool login = true,
      String? host,
      CancelToken? cancelToken,
      Function(int, int)? onSendProgress,
      Map<String, dynamic>? headers}) async {
    headers = headers ?? {};
    headers['Cookie'] = connectionStore.cookie;
    headers['Accept-Encoding'] = "gzip, deflate";
    headers['Accept'] = "*/*";
    // headers["Accept-Language"] = "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,zh-TW;q=0.5";
    // headers['origin'] = host ?? baseUrl;
    // headers['referer'] = host ?? baseUrl;
    // headers['Host'] = host ?? baseUrl;
    // headers['Connection'] = "keep-alive";
    // headers['User-Agent'] = "DS get 1.12.4 rv:168 (Dalvik/2.1.0 (Linux; U; Android 11; MI 9 Build/RKQ1.200826.002))";
    //Proxy-Connection: keep-alive
    // Log.info(headers);
    Dio dio = Dio(
      BaseOptions(
        baseUrl: "${host ?? connectionStore.baseUri}/webapi/",
        headers: headers,
      ),
    );
    // TODO: support proxy
    dio._createHttpClient(
        callback: (cert, host, port) {
          return !(connectionStore.checkSsl.value);
        },
        proxy: 'PROXY 192.168.1.73:8899; PROXY 127.0.0.1:8899; DIRECT');
    FormData formData = FormData.fromMap(data);
    Response response;
    try {
      response = await dio.post(
        url,
        queryParameters: params,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      if (response.data is String) {
        return json.decode(response.data);
      } else if (response.data is Map) {
        return response.data;
      }
    } on DioException catch (error) {
      Log.debug(
          "请求出错:$connectionStore.baseUrl/$url 请求内容:$data msg:${error.message}");
      return {
        "success": false,
        "error": {"code": error.message},
        "data": null
      };
    } catch (e) {
      Log.error("upload $url 出错:$e");
    }
  }

  Future<dynamic> downloadPkg(String saveName, String url, onReceiveProgress,
      CancelToken cancelToken) async {
    Dio dio = Dio();
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    Response response;

    try {
      dio._createHttpClient(
          callback: (cert, host, port) {
            return !(connectionStore.checkSsl.value);
          },
          proxy: 'PROXY 192.168.1.73:8899; PROXY 127.0.0.1:8899; DIRECT');
      response = await dio.download(
          url, tempPath + Platform.pathSeparator + saveName,
          deleteOnError: true,
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken);
      return {
        "code": response.statusCode,
        "msg": response.statusMessage,
        "data": tempPath + Platform.pathSeparator + saveName
      };
    } on DioException catch (error) {
      Log.debug("请求出错:$url $error");
      if (error.type == DioExceptionType.cancel) {
        return {"code": 0, "msg": "下载已取消", "data": null};
      } else {
        return {"code": 0, "msg": "网络错误", "data": null};
      }
    } catch (e) {
      Log.error("downloadPkg $url 出错:$e");
    }
  }
}
