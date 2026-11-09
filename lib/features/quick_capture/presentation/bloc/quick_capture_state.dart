import 'package:equatable/equatable.dart';

import '../../../../core/bloc/bloc_status.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/quick_capture_entities.dart';

class QuickCaptureState extends Equatable {
  final ParsedQuickCaptureIntentEntity? parsedIntent;

  /// Status of the *submit* operation (parsing is synchronous).
  final BlocStatus submitStatus;
  final Failure? failure;

  const QuickCaptureState({
    this.parsedIntent,
    this.submitStatus = BlocStatus.initial,
    this.failure,
  });

  bool get isSubmitting => submitStatus.isLoading;

  QuickCaptureState copyWith({
    ParsedQuickCaptureIntentEntity? parsedIntent,
    BlocStatus? submitStatus,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return QuickCaptureState(
      parsedIntent: parsedIntent ?? this.parsedIntent,
      submitStatus: submitStatus ?? this.submitStatus,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [parsedIntent, submitStatus, failure];
}
