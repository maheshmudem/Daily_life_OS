import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  static ApiClient? _instance;

  static const String defaultBaseUrl = 'https://api.dailylifeos.com/v1';

  /// Validates that [url] uses encrypted `https://` transport (allowing
  /// loopback `localhost` / `127.0.0.1` only when [allowLocalhostHttp] is true).
  static bool isSecureEndpoint(
    String url, {
    bool allowLocalhostHttp = !kReleaseMode,
  }) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') return true;
    if (scheme == 'http' && allowLocalhostHttp) {
      final host = uri.host.toLowerCase();
      return host == 'localhost' || host == '127.0.0.1' || host == '::1';
    }
    return false;
  }

  ApiClient._internal(
    FlutterSecureStorage secureStorage, {
    VoidCallback? onUnauthorized,
    String? baseUrlOverride,
  }) {
    String baseUrl;
    if (baseUrlOverride != null) {
      baseUrl = baseUrlOverride;
    } else {
      try {
        baseUrl = dotenv.env['API_BASE_URL'] ?? defaultBaseUrl;
      } catch (_) {
        baseUrl = defaultBaseUrl;
      }
    }

    if (!isSecureEndpoint(baseUrl)) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'Insecure cleartext HTTP endpoint rejected. HTTPS is required.',
      );
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Content-Type-Options': 'nosniff',
        },
      ),
    );

    _dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(secureStorage),
      ErrorInterceptor(secureStorage, onUnauthorized: onUnauthorized),
    ]);
  }

  factory ApiClient(
    FlutterSecureStorage secureStorage, {
    VoidCallback? onUnauthorized,
    String? baseUrlOverride,
  }) {
    if (baseUrlOverride != null) {
      return ApiClient._internal(
        secureStorage,
        onUnauthorized: onUnauthorized,
        baseUrlOverride: baseUrlOverride,
      );
    }
    _instance ??= ApiClient._internal(
      secureStorage,
      onUnauthorized: onUnauthorized,
    );
    return _instance!;
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
