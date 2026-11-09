import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';

import '../constants/string_constants.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Converts any thrown error into a domain [Failure].
///
/// Known exceptions keep their message; unknown errors are mapped to a generic
/// user-safe message so raw stack traces / SQL never reach the UI.
Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    CacheException(:final message) => CacheFailure(message: message),
    ValidationException(:final message, :final fieldErrors) =>
      ValidationFailure(message: message, fieldErrors: fieldErrors),
    NetworkException(:final message) => NetworkFailure(message: message),
    ServerException(:final message, :final code, :final statusCode) =>
      ServerFailure(message: message, code: code, statusCode: statusCode),
    _ => const CacheFailure(message: StringConstants.genericError),
  };
}

/// Runs a data-layer [action] and returns `Right(result)` or `Left(Failure)`.
///
/// This is the **single** place where repositories catch exceptions: data
/// sources throw, repositories call [guardRepositoryCall], and use cases /
/// BLoCs only ever see `Either<Failure, T>`. Unexpected errors are logged with
/// their stack trace before being mapped, so nothing fails silently.
Future<Either<Failure, T>> guardRepositoryCall<T>(
  Future<T> Function() action, {
  String context = 'repository',
}) async {
  try {
    return Right(await action());
  } on CacheException catch (e) {
    return Left(mapExceptionToFailure(e));
  } on ValidationException catch (e) {
    return Left(mapExceptionToFailure(e));
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected error in $context',
      name: 'DailyLifeOS.Data',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    return Left(mapExceptionToFailure(error));
  }
}
