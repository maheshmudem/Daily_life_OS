import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌── REQUEST ──────────────────────────────────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    if (options.headers['Authorization'] != null) {
      debugPrint('│ Auth: Bearer ***');
    }
    if (options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    debugPrint('└─────────────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌── RESPONSE ─────────────────────────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('└─────────────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌── ERROR ────────────────────────────────────────────────');
    debugPrint('│ ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('│ Message: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('│ Response: ${err.response?.data}');
    }
    debugPrint('└─────────────────────────────────────────────────────────');
    handler.next(err);
  }
}
