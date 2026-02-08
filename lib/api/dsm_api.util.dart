part of "dsm_api.dart";

extension DioExtension on Dio {
  _badCertificateCallback(BadCertificateCallback callback) {
    if (httpClientAdapter is IOHttpClientAdapter) {
      (httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        return HttpClient()..badCertificateCallback = callback;
      };
    } else {
      Log.warn(
          "DioExtension.badCertificateCallback: httpClientAdapter is not IOHttpClientAdapter");
    }
  }
}

final _dio = Dio(BaseOptions())
  ..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      String endpoint = options.extra['endpoint'] ?? '';
      if (endpoint.startsWith('http') || endpoint.startsWith('https')) {
        options.baseUrl = endpoint;
      } else {
        options.baseUrl =
            '${options.extra['host'] ?? connectionStore.baseUri}/$endpoint';
      }

      int timeout = options.extra['timeout'] ?? 30;
      options.connectTimeout = Duration(seconds: timeout);

      String cookie = options.extra['cookie'] ?? connectionStore.cookie.value;
      options
        ..headers["Accept-Language"] =
            "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,zh-TW;q=0.5"
        ..headers['origin'] = options.extra['host'] ?? connectionStore.baseUri
        ..headers['referer'] = options.extra['host'] ?? connectionStore.baseUri
        ..headers['Cookie'] = cookie
        ..headers['Content-Type'] =
            options.extra['Content-Type'] ?? 'application/json';
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
  ..interceptors.add(LogInterceptor(logPrint: Log.debug));

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
  int retryDelay = 1, // seconds
  Function(int, int)? onSendProgress,
  Function(int, int)? onReceiveProgress,
}) async {
  Response response;
  // TODO: retry
  try {
    if (!(checkSsl ?? connectionStore.checkSsl.value)) {
      _dio._badCertificateCallback((cert, host, port) => true);
    }
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
            'endpoint': endpoint,
            'timeout': timeout,
            'checkSsl': checkSsl,
            'cookie': cookie
          },
        ));
    if (response.data is String) {
      try {
        return jsonDecode(response.data);
      } on Exception catch (e) {
        Log.error('get: decode response as json failed: $e');
      }
    }
    if (response.data is Map) {
      return response.data as Map;
    }
    return response.data;
  } on DioException catch (e) {
    Log.error("get DioException: $e");
    rethrow;
  } catch (e) {
    Log.error("get: $e");
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
    Log.error("download DioException: $e");
    rethrow;
  } catch (e) {
    Log.error("download: $e");
    rethrow;
  }
}
