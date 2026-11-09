import 'dart:async';

import 'package:flutter/widgets.dart';

/// Subscribes to a BLoC effect stream (see `BlocEffectMixin`) and invokes
/// [listener] once per effect.
///
/// The subscription is tied to this widget's lifecycle: it is cancelled on
/// dispose and re-created if a different [effects] stream is supplied.
class BlocEffectListener<E> extends StatefulWidget {
  final Stream<E> effects;
  final void Function(BuildContext context, E effect) listener;
  final Widget child;

  const BlocEffectListener({
    super.key,
    required this.effects,
    required this.listener,
    required this.child,
  });

  @override
  State<BlocEffectListener<E>> createState() => _BlocEffectListenerState<E>();
}

class _BlocEffectListenerState<E> extends State<BlocEffectListener<E>> {
  StreamSubscription<E>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant BlocEffectListener<E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.effects, widget.effects)) {
      _subscription?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.effects.listen((effect) {
      if (mounted) widget.listener(context, effect);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
