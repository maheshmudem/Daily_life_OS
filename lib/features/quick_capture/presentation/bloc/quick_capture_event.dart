import 'package:equatable/equatable.dart';

import '../../domain/entities/quick_capture_entities.dart';

abstract class QuickCaptureEvent extends Equatable {
  const QuickCaptureEvent();

  @override
  List<Object?> get props => [];
}

class ParseQuickCaptureText extends QuickCaptureEvent {
  final String rawText;
  final DetectedIntent? manualOverride;

  const ParseQuickCaptureText(this.rawText, {this.manualOverride});

  @override
  List<Object?> get props => [rawText, manualOverride];
}

class SubmitQuickCapture extends QuickCaptureEvent {
  final QuickCaptureSubmissionEntity submission;

  const SubmitQuickCapture(this.submission);

  @override
  List<Object?> get props => [submission];
}

/// One-shot effects emitted by `QuickCaptureBloc`.
sealed class QuickCaptureEffect {
  const QuickCaptureEffect();
}

/// The capture was persisted; the sheet should close with [result].
final class QuickCaptureSubmitted extends QuickCaptureEffect {
  final QuickCaptureResult result;

  const QuickCaptureSubmitted(this.result);
}
