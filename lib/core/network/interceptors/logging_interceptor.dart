import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../monitoring/app_monitor.dart';

/// Sanitized HTTP telemetry interceptor.
///
/// - Never prints raw payloads or headers in release builds (`kDebugMode` only).
/// - Scrubs Bearer tokens, JWTs, passwords, PINs, API keys, and query secrets
///   via [AppMonitor.redact] before logging or recording breadcrumbs.
class LoggingInterceptor extends Interceptor {
  final AppMonitor _monitor;
  final void Function(String line)? logSink;

  LoggingInterceptor({AppMonitor? monitor, this.logSink})
    : _monitor = monitor ?? AppMonitor.instance;

  void _emitDebug(String line) {
    final safe = AppMonitor.redact(line);
    if (logSink != null) {
      logSink!(safe);
      return;
    }
    if (kDebugMode) {
      developer.log(safe, name: 'DailyLifeOS.Network');
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final safeUri = AppMonitor.redact(options.uri.toString());
    _monitor.recordBreadcrumb(
      category: 'network.request',
      message: '${options.method} $safeUri',
    );

    if (kDebugMode || logSink != null) {
      _emitDebug('┌── REQUEST ──────────────────────────────────────────────');
      _emitDebug('│ ${options.method} $safeUri');
      if (options.headers['Authorization'] != null) {
        _emitDebug('│ Auth: Bearer [REDACTED]');
      }
      if (options.data != null) {
        _emitDebug('│ Body: ${AppMonitor.redact(options.data.toString())}');
      }
      _emitDebug('└─────────────────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final safeUri = AppMonitor.redact(response.requestOptions.uri.toString());
    _monitor.recordBreadcrumb(
      category: 'network.response',
      message: '${response.statusCode} $safeUri',
    );

    if (kDebugMode || logSink != null) {
      _emitDebug('┌── RESPONSE ─────────────────────────────────────────────');
      _emitDebug('│ ${response.statusCode} $safeUri');
      _emitDebug('└─────────────────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final safeUri = AppMonitor.redact(err.requestOptions.uri.toString());
    _monitor.recordError(
      '${err.response?.statusCode ?? "ERR"} $safeUri: ${err.message ?? "Network failure"}',
      err.stackTrace,
      source: 'network',
    );

    if (kDebugMode || logSink != null) {
      _emitDebug('┌── ERROR ────────────────────────────────────────────────');
      _emitDebug('│ ${err.response?.statusCode} $safeUri');
      _emitDebug('│ Message: ${AppMonitor.redact(err.message ?? "")}');
      if (err.response?.data != null) {
        _emitDebug(
          '│ Response: ${AppMonitor.redact(err.response!.data.toString())}',
        );
      }
      _emitDebug('└─────────────────────────────────────────────────────────');
    }
    handler.next(err);
  }
}
