import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/error/failures.dart';
import 'package:daily_life_os/features/quick_capture/domain/entities/quick_capture_entities.dart';
import 'package:daily_life_os/features/quick_capture/domain/repositories/quick_capture_repository.dart';
import 'package:daily_life_os/features/quick_capture/domain/usecases/quick_capture_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQuickCaptureRepository extends Mock
    implements QuickCaptureRepository {}

QuickCaptureSubmissionEntity submission({
  DetectedIntent intent = DetectedIntent.expense,
  String rawText = 'Coffee',
  String amountText = '120',
  bool isTomorrow = false,
  String reminderTime = '05:00 PM',
}) {
  return QuickCaptureSubmissionEntity(
    mode: QuickCaptureMode.text,
    intent: intent,
    rawText: rawText,
    amountText: amountText,
    isIncome: false,
    expenseCategory: 'food',
    paymentMode: 'UPI',
    isTomorrow: isTomorrow,
    reminderTime: reminderTime,
    reminderPriority: 'medium',
    reminderCategory: 'Personal',
    habitCategory: 'Health',
    noteTag: '@QuickCapture',
    pinNote: false,
  );
}

void main() {
  late MockQuickCaptureRepository repository;
  // Fixed clock: 2026-11-07 10:00 → deterministic notification times.
  final fixedNow = DateTime(2026, 11, 7, 10);

  setUpAll(() {
    registerFallbackValue(QuickCaptureMode.text);
    registerFallbackValue(DateTime(2000));
  });

  setUp(() => repository = MockQuickCaptureRepository());

  SubmitQuickCaptureUseCase buildUseCase() =>
      SubmitQuickCaptureUseCase(repository, clock: () => fixedNow);

  void stubSaveTransaction(Either<Failure, Unit> result) {
    when(
      () => repository.saveTransaction(
        title: any(named: 'title'),
        amount: any(named: 'amount'),
        isIncome: any(named: 'isIncome'),
        category: any(named: 'category'),
        paymentMode: any(named: 'paymentMode'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => result);
  }

  void stubSaveReminder() {
    when(
      () => repository.saveReminder(
        title: any(named: 'title'),
        date: any(named: 'date'),
        time: any(named: 'time'),
        priority: any(named: 'priority'),
        category: any(named: 'category'),
        addToTodayTimeline: any(named: 'addToTodayTimeline'),
        notifyAt: any(named: 'notifyAt'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  }

  group('expense', () {
    test('rejects zero / invalid amounts with ValidationFailure', () async {
      final result = await buildUseCase()(submission(amountText: 'abc'));

      expect(
        result,
        const Left(ValidationFailure(message: StringConstants.invalidAmount)),
      );
      verifyZeroInteractions(repository);
    });

    test('saves transaction and routes to Money tab', () async {
      stubSaveTransaction(const Right(unit));

      final result = await buildUseCase()(submission());

      final capture = result.getOrElse(
        () => throw StateError('expected Right'),
      );
      expect(capture.targetTabIndex, 2);
      expect(capture.intent, DetectedIntent.expense);
      verify(
        () => repository.saveTransaction(
          title: 'Coffee',
          amount: 120,
          isIncome: false,
          category: 'food',
          paymentMode: 'UPI',
          source: QuickCaptureMode.text,
        ),
      ).called(1);
    });

    test('propagates repository failures unchanged', () async {
      const failure = CacheFailure(message: 'disk full');
      stubSaveTransaction(const Left(failure));

      final result = await buildUseCase()(submission());

      expect(result, const Left(failure));
    });

    test('uses a default title when the text is empty', () async {
      stubSaveTransaction(const Right(unit));

      await buildUseCase()(submission(rawText: '   '));

      verify(
        () => repository.saveTransaction(
          title: '${StringConstants.quickCaptureDefaultExpense} (FOOD)',
          amount: any(named: 'amount'),
          isIncome: any(named: 'isIncome'),
          category: any(named: 'category'),
          paymentMode: any(named: 'paymentMode'),
          source: any(named: 'source'),
        ),
      ).called(1);
    });
  });

  group('reminder', () {
    test('schedules notification at the chosen time today', () async {
      stubSaveReminder();

      await buildUseCase()(
        submission(intent: DetectedIntent.reminder, reminderTime: '05:00 PM'),
      );

      verify(
        () => repository.saveReminder(
          title: 'Coffee',
          date: DateTime(2026, 11, 7),
          time: '05:00 PM',
          priority: 'medium',
          category: 'Personal',
          addToTodayTimeline: true,
          notifyAt: DateTime(2026, 11, 7, 17),
          source: QuickCaptureMode.text,
        ),
      ).called(1);
    });

    test('does not notify for a time that already passed today', () async {
      stubSaveReminder();

      await buildUseCase()(
        submission(intent: DetectedIntent.reminder, reminderTime: '09:00 AM'),
      );

      verify(
        () => repository.saveReminder(
          title: any(named: 'title'),
          date: any(named: 'date'),
          time: any(named: 'time'),
          priority: any(named: 'priority'),
          category: any(named: 'category'),
          addToTodayTimeline: any(named: 'addToTodayTimeline'),
          notifyAt: null,
          source: any(named: 'source'),
        ),
      ).called(1);
    });

    test('tomorrow reminders skip the today timeline', () async {
      stubSaveReminder();

      final result = await buildUseCase()(
        submission(
          intent: DetectedIntent.reminder,
          isTomorrow: true,
          reminderTime: '12:30 AM',
        ),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => repository.saveReminder(
          title: any(named: 'title'),
          date: DateTime(2026, 11, 8),
          time: any(named: 'time'),
          priority: any(named: 'priority'),
          category: any(named: 'category'),
          addToTodayTimeline: false,
          notifyAt: DateTime(2026, 11, 8, 0, 30),
          source: any(named: 'source'),
        ),
      ).called(1);
    });
  });

  test('long notes get a truncated title but full content', () async {
    when(
      () => repository.saveNote(
        title: any(named: 'title'),
        content: any(named: 'content'),
        tag: any(named: 'tag'),
        isPinned: any(named: 'isPinned'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    final longText = 'a' * 60;

    final result = await buildUseCase()(
      submission(intent: DetectedIntent.note, rawText: longText),
    );

    expect(result.isRight(), isTrue);
    verify(
      () => repository.saveNote(
        title: '${'a' * SubmitQuickCaptureUseCase.maxNoteTitleLength}...',
        content: longText,
        tag: '@QuickCapture',
        isPinned: false,
      ),
    ).called(1);
  });
}
