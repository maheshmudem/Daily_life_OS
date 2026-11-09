import 'package:dartz/dartz.dart';

import '../../../../core/constants/string_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/currency_utils.dart';
import '../entities/quick_capture_entities.dart';
import '../repositories/quick_capture_repository.dart';
import '../services/quick_capture_intent_parser.dart';

/// Synchronous: parsing is pure CPU work with no I/O, so it does not need the
/// async `UseCase<T, Params>` contract.
class ParseQuickCaptureIntentUseCase {
  final QuickCaptureIntentParser _parser;

  const ParseQuickCaptureIntentUseCase(this._parser);

  ParsedQuickCaptureIntentEntity call(
    String rawText, {
    DetectedIntent? manualOverride,
  }) {
    return _parser.parse(rawText, manualOverride: manualOverride);
  }
}

/// Validates a capture, routes it to the right module and builds the
/// user-facing summary.
class SubmitQuickCaptureUseCase
    implements UseCase<QuickCaptureResult, QuickCaptureSubmissionEntity> {
  static const int maxNoteTitleLength = 48;

  static const int _todayTab = 0;
  static const int _plannerTab = 1;
  static const int _moneyTab = 2;
  static const int _notesTab = 3;

  final QuickCaptureRepository _repository;
  final DateTime Function() _now;

  SubmitQuickCaptureUseCase(this._repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  @override
  Future<Either<Failure, QuickCaptureResult>> call(
    QuickCaptureSubmissionEntity s,
  ) async {
    final title = _effectiveTitle(s);

    switch (s.intent) {
      case DetectedIntent.expense:
        final amount = double.tryParse(s.amountText.trim());
        if (amount == null || amount <= 0) {
          return const Left(
            ValidationFailure(message: StringConstants.invalidAmount),
          );
        }
        final saved = await _repository.saveTransaction(
          title: title,
          amount: amount,
          isIncome: s.isIncome,
          category: s.expenseCategory,
          paymentMode: s.paymentMode,
          source: s.mode,
        );
        return saved.map(
          (_) => QuickCaptureResult(
            intent: s.intent,
            summary:
                '${s.isIncome ? 'Income' : 'Expense'} ${CurrencyUtils.format(amount)} ($title)',
            targetTabIndex: _moneyTab,
          ),
        );

      case DetectedIntent.reminder:
        final now = _now();
        final day = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: s.isTomorrow ? 1 : 0));
        final saved = await _repository.saveReminder(
          title: title,
          date: day,
          time: s.reminderTime,
          priority: s.reminderPriority,
          category: s.reminderCategory,
          addToTodayTimeline: !s.isTomorrow,
          notifyAt: _resolveNotifyAt(day, s.reminderTime, now),
          source: s.mode,
        );
        return saved.map(
          (_) => QuickCaptureResult(
            intent: s.intent,
            summary:
                '"$title" (${s.isTomorrow ? 'Tomorrow' : 'Today'} at ${s.reminderTime})',
            targetTabIndex: _plannerTab,
          ),
        );

      case DetectedIntent.habit:
        final saved = await _repository.saveHabit(
          title: title,
          category: s.habitCategory,
        );
        return saved.map(
          (_) => QuickCaptureResult(
            intent: s.intent,
            summary: 'Habit "$title" (${s.habitCategory})',
            targetTabIndex: _todayTab,
          ),
        );

      case DetectedIntent.note:
        final saved = await _repository.saveNote(
          title: title.length > maxNoteTitleLength
              ? '${title.substring(0, maxNoteTitleLength)}...'
              : title,
          content: title,
          tag: s.noteTag,
          isPinned: s.pinNote,
        );
        return saved.map(
          (_) => QuickCaptureResult(
            intent: s.intent,
            summary: 'Note "$title" (${s.noteTag})',
            targetTabIndex: _notesTab,
          ),
        );
    }
  }

  String _effectiveTitle(QuickCaptureSubmissionEntity s) {
    final trimmed = s.rawText.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return switch (s.intent) {
      DetectedIntent.expense =>
        s.isIncome
            ? StringConstants.quickCaptureDefaultIncome
            : '${StringConstants.quickCaptureDefaultExpense} (${s.expenseCategory.toUpperCase()})',
      DetectedIntent.reminder => StringConstants.quickCaptureDefaultReminder,
      DetectedIntent.habit => StringConstants.quickCaptureDefaultHabit,
      DetectedIntent.note => StringConstants.quickCaptureDefaultNote,
    };
  }

  /// Converts `hh:mm AM` on [day] into a notification time.
  /// Returns `null` for unparseable or past times (nothing to remind about).
  static DateTime? _resolveNotifyAt(DateTime day, String time, DateTime now) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(time.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPm = match.group(3)!.toUpperCase() == 'PM';
    if (hour < 1 || hour > 12 || minute > 59) return null;
    if (hour == 12) hour = 0;
    if (isPm) hour += 12;
    final at = DateTime(day.year, day.month, day.day, hour, minute);
    return at.isAfter(now) ? at : null;
  }
}
