import 'package:dio/dio.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/log.dart';

/// DSM API 调用辅助函数，统一处理异常
Future<Map?> callDsmApi(Future<Map> Function() apiCall) async {
  try {
    return await apiCall();
  } on DSMException catch (e) {
    Log.error('DSM API Error: ${e.code} - ${e.message}');
    return {'success': false, 'error': {'code': e.code}};
  } on DioException catch (e) {
    Log.error('Network Error: ${e.message}');
    return {'success': false, 'error': {'code': e.message}};
  } catch (e) {
    Log.error('Unknown Error: $e');
    return {'success': false, 'error': {'code': e.toString()}};
  }
}
