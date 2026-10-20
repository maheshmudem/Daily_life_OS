import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constants/app_constants.dart';
import '../../error/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final VoidCallback? onUnauthorized;

  ErrorInterceptor(this._secureStorage, {this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const ServerException(
            message: 'Network connection error. Please check your internet connection.',
            code: 'NETWORK_ERROR',
          ),
          type: err.type,
          response: err.response,
        ),
      );
    }

    if (statusCode != null) {
      final errorCode = data is Map ? data['code'] as String? : null;
      final errorMessage = data is Map
          ? (data['error'] as String? ?? data['message'] as String? ?? 'An error occurred')
          : 'An error occurred';

      switch (statusCode) {
        case 400:
          final _ = data is Map && data['fieldErrors'] is Map
              ? Map<String, String>.from(data['fieldErrors'] as Map)
              : null;
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ServerException(
                message: errorMessage,
                code: errorCode ?? 'VALIDATION_ERROR',
                statusCode: 400,
              ),
              response: err.response,
              type: err.type,
            ),
          );

        case 401:
          if (errorCode == 'INVALID_CREDENTIALS') {
            return handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                error: const ServerException(
                  message: 'Invalid email or password.',
                  code: 'INVALID_CREDENTIALS',
                  statusCode: 401,
                ),
                response: err.response,
                type: err.type,
              ),
            );
          }
          // UNAUTHORIZED - clear token and redirect
          await _secureStorage.delete(key: AppConstants.jwtTokenKey);
          onUnauthorized?.call();
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const ServerException(
                message: 'Your session has expired. Please log in again.',
                code: 'UNAUTHORIZED',
                statusCode: 401,
              ),
              response: err.response,
              type: err.type,
            ),
          );

        case 403:
          if (errorCode == 'EMAIL_NOT_VERIFIED') {
            return handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                error: const ServerException(
                  message: 'Please verify your email to continue.',
                  code: 'EMAIL_NOT_VERIFIED',
                  statusCode: 403,
                ),
                response: err.response,
                type: err.type,
              ),
            );
          }
          if (errorCode == 'ACCOUNT_INACTIVE') {
            return handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                error: const ServerException(
                  message: 'Account deactivated. Please contact support.',
                  code: 'ACCOUNT_INACTIVE',
                  statusCode: 403,
                ),
                response: err.response,
                type: err.type,
              ),
            );
          }
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ServerException(
                message: errorMessage,
                code: errorCode ?? 'FORBIDDEN',
                statusCode: 403,
              ),
              response: err.response,
              type: err.type,
            ),
          );

        case 404:
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ServerException(
                message: errorMessage.isNotEmpty ? errorMessage : 'Resource not found.',
                code: 'NOT_FOUND',
                statusCode: 404,
              ),
              response: err.response,
              type: err.type,
            ),
          );

        case 423:
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const ServerException(
                message: 'Account locked. Please contact support.',
                code: 'ACCOUNT_LOCKED',
                statusCode: 423,
              ),
              response: err.response,
              type: err.type,
            ),
          );

        case 429:
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const ServerException(
                message: 'Too many requests. Please try again later.',
                code: 'RATE_LIMITED',
                statusCode: 429,
              ),
              response: err.response,
              type: err.type,
            ),
          );

        case 500:
        default:
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const ServerException(
                message: 'Something went wrong. Please try again.',
                code: 'INTERNAL_ERROR',
                statusCode: 500,
              ),
              response: err.response,
              type: err.type,
            ),
          );
      }
    }

    handler.next(err);
  }
}

typedef VoidCallback = void Function();
