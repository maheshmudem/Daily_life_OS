import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global [BlocObserver] registered in `main.dart`.
///
/// - Errors thrown inside any bloc are always logged, so failures are never
///   silent.
/// - Transitions are logged only in debug builds to aid development without
///   adding noise or overhead in release builds.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  static const String _logName = 'DailyLifeOS.Bloc';

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      developer.log(
        '${bloc.runtimeType}: ${transition.event.runtimeType}',
        name: _logName,
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      '${bloc.runtimeType} error',
      name: _logName,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    super.onError(bloc, error, stackTrace);
  }
}
