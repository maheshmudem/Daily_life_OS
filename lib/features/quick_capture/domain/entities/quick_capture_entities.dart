import 'package:equatable/equatable.dart';

enum QuickCaptureMode { text, voice, scan }

enum DetectedIntent { expense, reminder, habit, note }

/// Result returned when QuickCaptureSheet logs an item so the caller
/// can refresh state and optionally jump to the target tab.
class QuickCaptureResult extends Equatable {
  final DetectedIntent intent;
  final String summary;
  final int targetTabIndex; // 0: Today, 1: Planner, 2: Money, 3: Notes

  const QuickCaptureResult({
    required this.intent,
    required this.summary,
    required this.targetTabIndex,
  });

  @override
  List<Object?> get props => [intent, summary, targetTabIndex];
}

/// Parsed NLP fields extracted from user input.
class ParsedQuickCaptureIntentEntity extends Equatable {
  final DetectedIntent detectedIntent;
  final String? extractedAmount;
  final String? extractedTime;
  final bool? isTomorrow;
  final String? reminderPriority;
  final bool? isIncome;
  final String? expenseCategory;
  final String? paymentMode;
  final String? noteTag;

  const ParsedQuickCaptureIntentEntity({
    required this.detectedIntent,
    this.extractedAmount,
    this.extractedTime,
    this.isTomorrow,
    this.reminderPriority,
    this.isIncome,
    this.expenseCategory,
    this.paymentMode,
    this.noteTag,
  });

  @override
  List<Object?> get props => [
    detectedIntent,
    extractedAmount,
    extractedTime,
    isTomorrow,
    reminderPriority,
    isIncome,
    expenseCategory,
    paymentMode,
    noteTag,
  ];
}

/// Payload submitted when saving a quick capture entry.
class QuickCaptureSubmissionEntity extends Equatable {
  final QuickCaptureMode mode;
  final DetectedIntent intent;
  final String rawText;
  final String amountText;
  final bool isIncome;
  final String expenseCategory;
  final String paymentMode;
  final bool isTomorrow;
  final String reminderTime;
  final String reminderPriority;
  final String reminderCategory;
  final String habitCategory;
  final String noteTag;
  final bool pinNote;

  const QuickCaptureSubmissionEntity({
    required this.mode,
    required this.intent,
    required this.rawText,
    required this.amountText,
    required this.isIncome,
    required this.expenseCategory,
    required this.paymentMode,
    required this.isTomorrow,
    required this.reminderTime,
    required this.reminderPriority,
    required this.reminderCategory,
    required this.habitCategory,
    required this.noteTag,
    required this.pinNote,
  });

  @override
  List<Object?> get props => [
    mode,
    intent,
    rawText,
    amountText,
    isIncome,
    expenseCategory,
    paymentMode,
    isTomorrow,
    reminderTime,
    reminderPriority,
    reminderCategory,
    habitCategory,
    noteTag,
    pinNote,
  ];
}
