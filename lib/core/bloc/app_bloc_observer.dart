import 'package:flutter_bloc/flutter_bloc.dart';

import '../monitoring/app_monitor.dart';

/// Global [BlocObserver] registered in `main.dart`.
///
/// - Forwards BLoC transitions and uncaught BLoC errors into [AppMonitor] with
///   automatic PII/secret redaction.
/// - Avoids string-formatting overhead in release builds.
class AppBlocObserver extends BlocObserver {
  final AppMonitor? monitor;

  const AppBlocObserver({this.monitor});

  AppMonitor get _activeMonitor => monitor ?? AppMonitor.instance;

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _activeMonitor.recordBlocTransition(
      '${bloc.runtimeType}',
      '${transition.event.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _activeMonitor.recordError(
      error,
      stackTrace,
      source: 'bloc.${bloc.runtimeType}',
      notifyUser: true,
    );
    super.onError(bloc, error, stackTrace);
  }
}
