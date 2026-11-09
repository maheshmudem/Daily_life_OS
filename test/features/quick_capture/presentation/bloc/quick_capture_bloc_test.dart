import 'package:bloc_test/bloc_test.dart';
import 'package:daily_life_os/core/bloc/bloc_status.dart';
import 'package:daily_life_os/core/error/failures.dart';
import 'package:daily_life_os/features/quick_capture/domain/entities/quick_capture_entities.dart';
import 'package:daily_life_os/features/quick_capture/domain/services/quick_capture_intent_parser.dart';
import 'package:daily_life_os/features/quick_capture/domain/usecases/quick_capture_usecases.dart';
import 'package:daily_life_os/features/quick_capture/presentation/bloc/quick_capture_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubmitQuickCaptureUseCase extends Mock
    implements SubmitQuickCaptureUseCase {}

const _submission = QuickCaptureSubmissionEntity(
  mode: QuickCaptureMode.text,
  intent: DetectedIntent.note,
  rawText: 'Idea',
  amountText: '0',
  isIncome: false,
  expenseCategory: 'other',
  paymentMode: 'UPI',
  isTomorrow: false,
  reminderTime: '05:00 PM',
  reminderPriority: 'medium',
  reminderCategory: 'Personal',
  habitCategory: 'Health',
  noteTag: '@QuickCapture',
  pinNote: false,
);

const _result = QuickCaptureResult(
  intent: DetectedIntent.note,
  summary: 'Note "Idea" (@QuickCapture)',
  targetTabIndex: 3,
);

void main() {
  late MockSubmitQuickCaptureUseCase submit;

  setUpAll(() => registerFallbackValue(_submission));
  setUp(() => submit = MockSubmitQuickCaptureUseCase());

  QuickCaptureBloc buildBloc() => QuickCaptureBloc(
    parseQuickCaptureIntentUseCase: const ParseQuickCaptureIntentUseCase(
      QuickCaptureIntentParser(),
    ),
    submitQuickCaptureUseCase: submit,
  );

  blocTest<QuickCaptureBloc, QuickCaptureState>(
    'ParseQuickCaptureText emits the parsed intent',
    build: buildBloc,
    act: (bloc) => bloc.add(const ParseQuickCaptureText('Spent ₹99 on lunch')),
    verify: (bloc) {
      expect(bloc.state.parsedIntent?.detectedIntent, DetectedIntent.expense);
      expect(bloc.state.parsedIntent?.extractedAmount, '99');
    },
  );

  test(
    'successful submit emits loading → success and one Submitted effect',
    () async {
      when(() => submit(any())).thenAnswer((_) async => const Right(_result));
      final bloc = buildBloc();
      final effects = <QuickCaptureEffect>[];
      final sub = bloc.effects.listen(effects.add);

      bloc.add(const SubmitQuickCapture(_submission));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QuickCaptureState>().having(
            (s) => s.submitStatus,
            'status',
            BlocStatus.loading,
          ),
          isA<QuickCaptureState>().having(
            (s) => s.submitStatus,
            'status',
            BlocStatus.success,
          ),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(effects, hasLength(1));
      expect((effects.single as QuickCaptureSubmitted).result, _result);
      await sub.cancel();
      await bloc.close();
    },
  );

  blocTest<QuickCaptureBloc, QuickCaptureState>(
    'failed submit exposes the failure and emits no effect',
    build: () {
      when(
        () => submit(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const SubmitQuickCapture(_submission)),
    expect: () => const [
      QuickCaptureState(submitStatus: BlocStatus.loading),
      QuickCaptureState(
        submitStatus: BlocStatus.failure,
        failure: CacheFailure(message: 'disk full'),
      ),
    ],
  );

  blocTest<QuickCaptureBloc, QuickCaptureState>(
    'ignores a second submit while the first is in flight (no double save)',
    build: () {
      when(() => submit(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const Right(_result);
      });
      return buildBloc();
    },
    act: (bloc) => bloc
      ..add(const SubmitQuickCapture(_submission))
      ..add(const SubmitQuickCapture(_submission)),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => submit(any())).called(1),
  );
}
