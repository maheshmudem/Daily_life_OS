import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/bloc_effect_mixin.dart';
import '../../../../core/bloc/bloc_status.dart';
import '../../domain/usecases/quick_capture_usecases.dart';
import 'quick_capture_event.dart';
import 'quick_capture_state.dart';

export 'quick_capture_event.dart';
export 'quick_capture_state.dart';

class QuickCaptureBloc extends Bloc<QuickCaptureEvent, QuickCaptureState>
    with
        BlocEffectMixin<
          QuickCaptureEvent,
          QuickCaptureState,
          QuickCaptureEffect
        > {
  final ParseQuickCaptureIntentUseCase _parseIntent;
  final SubmitQuickCaptureUseCase _submit;

  QuickCaptureBloc({
    required ParseQuickCaptureIntentUseCase parseQuickCaptureIntentUseCase,
    required SubmitQuickCaptureUseCase submitQuickCaptureUseCase,
  }) : _parseIntent = parseQuickCaptureIntentUseCase,
       _submit = submitQuickCaptureUseCase,
       super(const QuickCaptureState()) {
    on<ParseQuickCaptureText>(_onParseText);
    on<SubmitQuickCapture>(_onSubmit);
  }

  void _onParseText(
    ParseQuickCaptureText event,
    Emitter<QuickCaptureState> emit,
  ) {
    final parsed = _parseIntent(
      event.rawText,
      manualOverride: event.manualOverride,
    );
    emit(state.copyWith(parsedIntent: parsed, clearFailure: true));
  }

  Future<void> _onSubmit(
    SubmitQuickCapture event,
    Emitter<QuickCaptureState> emit,
  ) async {
    // Guard against double taps while a save is in flight.
    if (state.isSubmitting) return;

    emit(state.copyWith(submitStatus: BlocStatus.loading, clearFailure: true));
    final result = await _submit(event.submission);
    result.fold(
      (failure) => emit(
        state.copyWith(submitStatus: BlocStatus.failure, failure: failure),
      ),
      (captureResult) {
        emit(state.copyWith(submitStatus: BlocStatus.success));
        emitEffect(QuickCaptureSubmitted(captureResult));
      },
    );
  }
}
