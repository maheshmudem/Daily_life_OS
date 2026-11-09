import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds a one-shot **effect** stream to a [Bloc].
///
/// State describes *what the screen looks like*; effects describe *things that
/// should happen exactly once* (pop a sheet, show a snackbar, call an unlock
/// callback). Keeping them separate prevents an action from firing again when
/// unrelated state fields change or when a widget rebuilds.
///
/// Effects are delivered on a broadcast stream, so an effect emitted while no
/// listener is attached is dropped. Listen with `BlocEffectListener`.
mixin BlocEffectMixin<Event, State, Effect> on Bloc<Event, State> {
  final StreamController<Effect> _effectController =
      StreamController<Effect>.broadcast();

  /// Stream of one-shot effects for the UI layer.
  Stream<Effect> get effects => _effectController.stream;

  /// Emits a one-shot [effect]. Ignored after the bloc is closed.
  @protected
  void emitEffect(Effect effect) {
    if (!_effectController.isClosed) {
      _effectController.add(effect);
    }
  }

  @override
  Future<void> close() async {
    await _effectController.close();
    return super.close();
  }
}
