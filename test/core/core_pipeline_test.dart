import 'dart:async';

import 'package:daily_life_os/core/bloc/bloc_effect_mixin.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/error/exceptions.dart';
import 'package:daily_life_os/core/error/failure_mapper.dart';
import 'package:daily_life_os/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _PingBloc extends Bloc<int, int> with BlocEffectMixin<int, int, String> {
  _PingBloc() : super(0) {
    on<int>((event, emit) => emitEffect('ping $event'));
  }
}

void main() {
  group('guardRepositoryCall', () {
    test('wraps successful results in Right', () async {
      expect(await guardRepositoryCall(() async => 42), const Right(42));
    });

    test('maps CacheException to CacheFailure keeping the message', () async {
      final result = await guardRepositoryCall<int>(
        () async => throw const CacheException(message: 'disk full'),
      );
      expect(result, const Left(CacheFailure(message: 'disk full')));
    });

    test('maps ValidationException to ValidationFailure', () async {
      final result = await guardRepositoryCall<int>(
        () async => throw const ValidationException(message: 'bad'),
      );
      expect(result, const Left(ValidationFailure(message: 'bad')));
    });

    test('maps unknown errors to a generic, user-safe failure', () async {
      final result = await guardRepositoryCall<int>(
        () async => throw StateError('SQL: no such table'),
      );
      expect(
        result,
        const Left(CacheFailure(message: StringConstants.genericError)),
      );
    });
  });

  group('BlocEffectMixin', () {
    test('delivers effects once and closes the stream with the bloc', () async {
      final bloc = _PingBloc();
      final effects = <String>[];
      final done = Completer<void>();
      bloc.effects.listen(effects.add, onDone: done.complete);

      bloc
        ..add(1)
        ..add(2);
      await Future<void>.delayed(Duration.zero);
      await bloc.close();
      await done.future;

      expect(effects, ['ping 1', 'ping 2']);
    });
  });
}
