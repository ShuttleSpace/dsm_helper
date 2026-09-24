part of "dsm_api.dart";

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
//Log.warn(
//"DioExtension.badCertificateCallback: httpClientAdapter is not IOHttpClientAdapter");
    }
  }
}

final _httpClient = HttpClient();
final _cookieJar = CookieJar();
final _dio = Dio(BaseOptions(
  baseUrl: '${connectionStore.baseUri.value}/',
))
  ..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      int timeout = options.extra['timeout'] ?? 30;
      options.connectTimeout = Duration(seconds: timeout);
      options
            ..headers["Accept-Language"] =
                "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,zh-TW;q=0.5"
            ..headers['Origin'] =
                options.extra['host'] ?? connectionStore.baseUri
            ..headers['Referer'] =
                options.extra['host'] ?? connectionStore.baseUri
            ..headers['Content-Type'] = options.extra['Content-Type'] ??
                'application/json; charset="UTF-8'
            ..headers['Accept-Encoding'] = 'gzip, deflate, br'
            ..headers['Accept'] = '*/*'
            ..headers['X-SYNO-TOKEN'] = connectionStore.synoToken.value
          // ..headers['X-SYNO-HASH'] = connectionStore.cookie.value
          ;
      handler.next(options);
    },
    onResponse: (response, handler) {
      if (response.headers['set-cookie'] != null &&
          response.headers['set-cookie']!.isNotEmpty) {
        List cookies = [];
        String did = '';
        if (connectionStore.cookie.value.isNotEmpty) {
          List originCookies = connectionStore.cookie.value.split('; ');
          for (String str in originCookies) {
            Cookie cookie = Cookie.fromSetCookieValue(str);
            if (cookie.name == 'did') {
              did = cookie.value;
            }
          }
        }
        bool hasDid = false;
        for (String str in response.headers['set-cookie']!) {
          Cookie cookie = Cookie.fromSetCookieValue(str);
          if (cookie.name == 'did') {
            hasDid = true;
          }
          cookies.add('${cookie.name}=${cookie.value}');
        }
        if (!hasDid && did.isNotEmpty) {
          cookies.add('did=$did');
        }
        connectionStore.setCookie(cookies.join('; '));
      }
      handler.next(response);
    },
    onError: (e, handler) {
      handler.next(e);
    },
  ))
  ..interceptors.add(CookieManager(_cookieJar))
  // ..interceptors.add(LogInterceptor(
  //     request: false,
  //     requestUrl: false,
  //     requestBody: false,
  //     requestHeader: false,
  //     responseUrl: false,
  //     responseBody: false,
  //     responseHeader: false))
  ..options.followRedirects = false
  ..options.validateStatus =
      (status) => (status != null && status >= 200 && status < 400);

Future<dynamic> _httpRequest(
  String endpoint, {
  String method = 'GET',
  String? host,
  Map<String, dynamic>? headers,
  Object? data,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  bool? checkSsl,
  String? cookie,
  int timeout = 30,
  int maxRetry = 3,
  int retryDelay = 0, // seconds
  Function(int, int)? onSendProgress,
  Function(int, int)? onReceiveProgress,
}) async {
  dynamic response;
  do {
    maxRetry--;
    response = await Future.delayed(Duration(seconds: retryDelay), () async {
      return await _doHttpRequest(endpoint,
          method: method,
          host: host,
          headers: headers,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          checkSsl: checkSsl,
          cookie: cookie,
          timeout: timeout,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress);
    });
  } while (response != null && maxRetry > 0);
  return response;
}

Future<dynamic> _doHttpRequest(
  String endpoint, {
  String method = 'GET',
  String? host,
  Map<String, dynamic>? headers,
  Object? data,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  bool? checkSsl,
  String? cookie,
  int timeout = 30,
  Function(int, int)? onSendProgress,
  Function(int, int)? onReceiveProgress,
}) async {
  Response response;
  try {
    _dio._createHttpClient(
        callback: (cert, host, port) {
          return !(checkSsl ?? connectionStore.checkSsl.value);
        },
        proxy: 'PROXY 192.168.8.76:8899; PROXY 127.0.0.1:8899; DIRECT');
    response = await _dio.request(endpoint,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          method: method,
          headers: headers ?? {},
          extra: {
            'host': host,
            'timeout': timeout,
            'checkSsl': checkSsl,
            'cookie': cookie
          },
        ));
    if (response.data is String) {
      try {
        return jsonDecode(response.data);
      } on Exception catch (e) {
        //Log.error('_httpRequest: decode response as json failed: $e');
      }
    }
    if (response.data is Map) {
      return response.data as Map;
    }
    return response.data;
  } on DioException catch (e) {
    //Log.error("_httpRequest DioException: $e");
    rethrow;
  } catch (e) {
    //Log.error("_httpRequest Exception: $e");
    rethrow;
  }
}

Future<dynamic> _httpGet(
  String endpoint, {
  String? host,
  Map<String, dynamic>? headers,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  bool? checkSsl,
  String? cookie,
  int timeout = 30,
}) async {
  return _httpRequest(endpoint,
      method: 'GET',
      host: host,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      checkSsl: checkSsl,
      cookie: cookie,
      timeout: timeout);
}

Future<dynamic> _httpPost(
  String endpoint, {
  String? host,
  Map<String, dynamic>? headers,
  Object? data,
  CancelToken? cancelToken,
  bool? checkSsl,
  String? cookie,
  int timeout = 30,
}) async {
  return _httpRequest(endpoint,
      method: 'POST',
      host: host,
      headers: headers,
      data: data,
      cancelToken: cancelToken,
      checkSsl: checkSsl,
      cookie: cookie,
      timeout: timeout);
}

// ignore: unused_element
Future<dynamic> _httpUpload(
  String endpoint, {
  required Object data,
  String? host,
  Map<String, dynamic>? headers,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  bool? checkSsl,
  String? cookie,
  int timeout = 30,
  Function(int, int)? onSendProgress,
}) async {
  headers ??= {};
  headers['Accept-Encoding'] = "gzip, deflate";
  headers['Accept'] = "*/*";
  return _httpRequest(endpoint,
      method: 'POST',
      host: host,
      headers: headers,
      queryParameters: queryParameters,
      data: data,
      cancelToken: cancelToken,
      checkSsl: checkSsl,
      cookie: cookie,
      onSendProgress: onSendProgress,
      timeout: timeout);
}

Future<dynamic> _httpDownload(String endpoint,
    {required String savePath,
    String? host,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool? checkSsl,
    String? cookie,
    int timeout = 30,
    Function(int, int)? onReceiveProgress}) async {
  Response response;
  try {
    response = await _dio.download(endpoint, savePath,
        deleteOnError: true,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        queryParameters: queryParameters,
        options: Options(
          method: 'GET',
          headers: headers ?? {},
          extra: {
            'host': host,
            'endpoint': endpoint,
            'timeout': timeout,
            'checkSsl': checkSsl,
            'cookie': cookie
          },
        ));
    return response.data;
  } on DioException catch (e) {
//Log.error("download DioException: $e");
    rethrow;
  } catch (e) {
//Log.error("download: $e");
    rethrow;
  }
}
