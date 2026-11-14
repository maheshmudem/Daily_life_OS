import 'dart:async';

import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/bloc/app_bloc_observer.dart';
import 'package:daily_life_os/core/error/exceptions.dart';
import 'package:daily_life_os/core/error/failures.dart';
import 'package:daily_life_os/core/monitoring/app_monitor.dart';
import 'package:daily_life_os/core/utils/snackbar_utils.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:daily_life_os/core/widgets/app_user_error_banner.dart';
import 'package:daily_life_os/core/widgets/feature_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestCounterCubit extends Cubit<int> {
  _TestCounterCubit() : super(0);

  void triggerFailure() {
    addError(
      StateError('Failed auth token=mySecretToken999'),
      StackTrace.current,
    );
  }
}

void _expectZeroTechnicalWords(UserFriendlyError friendly) {
  final allUserStrings = [
    friendly.title,
    friendly.message,
    friendly.reassurance,
    friendly.actionHint,
    friendly.actionLabel,
    friendly.snackbarMessage,
  ];

  const bannedWords = <String>[
    'exception',
    'stacktrace',
    'sqlite',
    'drift',
    'database',
    'foreign key',
    'constraint',
    'dio',
    'socket',
    'errno',
    'http',
    '500',
    '404',
    '401',
    '429',
    'null',
    'stateerror',
    'bad state',
    'bloc',
    'cubit',
    'json',
    'cachefailure',
    'serverfailure',
    'renderflex',
  ];

  for (final text in allUserStrings) {
    expect(
      AppMonitor.containsTechnicalJargon(text),
      isFalse,
      reason: 'User-facing text leaked technical jargon: "$text"',
    );
    final lower = text.toLowerCase();
    for (final banned in bannedWords) {
      expect(
        lower,
        isNot(contains(banned)),
        reason: 'User-facing text "$text" contained banned word "$banned"',
      );
    }
  }
}

void main() {
  group('AppMonitor — Production Telemetry, Redaction & User-POV Error Suite', () {
    late AppMonitor monitor;

    setUp(() {
      monitor = AppMonitor(
        maxBreadcrumbs: 10,
        maxErrors: 5,
        maxSpans: 8,
        alertCooldown: const Duration(seconds: 4),
      );
    });

    test(
      'redacts Bearer tokens, JWTs, passwords, PINs, query keys, and card PANs',
      () {
        const fakeJwt =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFhcmF2In0.'
            'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        const raw =
            'Auth: Bearer secret_live_tok_12345 '
            'jwt=$fakeJwt '
            'url=https://api.example.com/login?api_key=xyz987&pin=4829 '
            'body={"password":"SuperSecret!1","decoyPin":"9999","cvv":"842"} '
            'card=4532 1488 0343 6467';

        final sanitized = AppMonitor.redact(raw);

        expect(sanitized, isNot(contains('secret_live_tok_12345')));
        expect(
          sanitized,
          isNot(contains('SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV')),
        );
        expect(sanitized, isNot(contains('xyz987')));
        expect(sanitized, isNot(contains('4829')));
        expect(sanitized, isNot(contains('SuperSecret!1')));
        expect(sanitized, isNot(contains('9999')));
        expect(sanitized, isNot(contains('4532 1488 0343 6467')));
        expect(sanitized, contains('Bearer [REDACTED]'));
        expect(sanitized, contains('[REDACTED_JWT]'));
        expect(sanitized, contains('[REDACTED_CARD]'));
      },
    );

    test('enforces O(1) bounded ring buffers without memory growth', () {
      for (var i = 0; i < 35; i++) {
        monitor.recordBreadcrumb(category: 'nav', message: 'Step $i');
      }
      for (var i = 0; i < 20; i++) {
        monitor.recordError('Err $i', StackTrace.current);
      }
      for (var i = 0; i < 25; i++) {
        monitor.recordSpan('db.query.$i', Duration(milliseconds: i));
      }

      final snap = monitor.snapshot();
      expect(snap.recentBreadcrumbs.length, 10);
      expect(snap.recentBreadcrumbs.last.message, 'Err 19');
      expect(snap.recentErrors.length, 5);
      expect(snap.totalErrors, 20);
      expect(snap.recentSpans.length, 8);
    });

    test('traces async and sync spans and captures rethrown errors', () async {
      final result = await monitor.traceAsync('db.loadHabits', () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 42;
      });
      expect(result, 42);

      final syncVal = monitor.traceSync('nlp.parse', () => 'parsed');
      expect(syncVal, 'parsed');

      await expectLater(
        () => monitor.traceAsync(
          'api.sync',
          () async => throw Exception('password=TopSecretFailure'),
        ),
        throwsException,
      );

      final snap = monitor.snapshot();
      expect(snap.recentSpans.length, 3);
      expect(snap.recentSpans.where((s) => s.success).length, 2);
      expect(snap.recentSpans.where((s) => !s.success).length, 1);
      expect(
        snap.recentErrors.single.message,
        isNot(contains('TopSecretFailure')),
      );
    });

    test(
      'tracks frame jank ratios, health status, and plain-English user support summary',
      () {
        monitor.recordStartupDuration(const Duration(milliseconds: 145));
        for (var i = 0; i < 9; i++) {
          monitor.recordFrameDurationMs(11);
        }
        monitor.recordFrameDurationMs(38);

        var snap = monitor.snapshot();
        expect(snap.status, AppHealthStatus.healthy);
        expect(snap.userStatusLabel, 'Running Smoothly');
        expect(snap.startupDurationMs, 145);
        expect(snap.totalFrames, 10);
        expect(snap.jankFrames, 1);
        expect(snap.severeJankFrames, 1);
        expect(snap.jankRatio, closeTo(0.10, 0.001));

        monitor.recordSecurityEvent('lockout_1', blocked: true);
        monitor.recordSecurityEvent('lockout_2', blocked: true);
        monitor.recordSecurityEvent('lockout_3', blocked: true);
        snap = monitor.snapshot();
        expect(snap.status, AppHealthStatus.degraded);
        expect(snap.userStatusLabel, 'Recovering Smoothly');

        monitor.recordError(
          const CacheException(
            message: 'SqliteException(787): FOREIGN KEY constraint failed',
          ),
          StackTrace.current,
          fatal: true,
        );
        snap = monitor.snapshot();
        expect(snap.status, AppHealthStatus.critical);
        expect(snap.toDiagnosticReport(), contains('Attention Needed'));

        final userSummary = snap.toUserSupportSummary();
        expect(userSummary, contains('APP CARE & SUPPORT SUMMARY'));
        expect(userSummary, isNot(contains('SqliteException')));
        expect(userSummary, isNot(contains('FOREIGN KEY')));
        expect(userSummary, isNot(contains('BLoC')));
        expect(AppMonitor.containsTechnicalJargon(userSummary), isFalse);
      },
    );

    test(
      'translates every technical error category into warm user-POV language without technical words',
      () {
        final cases = <(Object?, UserErrorCategory)>[
          (
            const NetworkFailure(message: 'SocketException: errno = 7'),
            UserErrorCategory.offline,
          ),
          (
            'DioException [connection error]: SocketException: Failed host lookup: api.os.local',
            UserErrorCategory.offline,
          ),
          (
            TimeoutException('Request timed out after 30s'),
            UserErrorCategory.timeout,
          ),
          (
            const CacheFailure(
              message: 'SqliteException(787): FOREIGN KEY constraint failed',
            ),
            UserErrorCategory.storage,
          ),
          (
            const CacheException(message: 'Database closed unexpectedly'),
            UserErrorCategory.storage,
          ),
          (
            'PlatformException(camera_access_denied, User denied camera permission)',
            UserErrorCategory.permission,
          ),
          (
            const ServerException(
              message: 'HTTP 401 Unauthorized token expired',
              statusCode: 401,
            ),
            UserErrorCategory.security,
          ),
          (
            const ServerException(
              message: 'HTTP 404 Resource Not Found',
              statusCode: 404,
            ),
            UserErrorCategory.notFound,
          ),
          (StateError('Bad state: No element'), UserErrorCategory.notFound),
          (
            const ServerException(
              message: 'HTTP 429 Too Many Requests',
              statusCode: 429,
            ),
            UserErrorCategory.busy,
          ),
          (
            const FormatException('Unexpected character (at character 1)'),
            UserErrorCategory.input,
          ),
          (
            const ServerException(
              message: 'HTTP 500 Internal Server Error',
              statusCode: 500,
            ),
            UserErrorCategory.unexpected,
          ),
          (
            'Null check operator used on a null value',
            UserErrorCategory.unexpected,
          ),
          (null, UserErrorCategory.unexpected),
        ];

        for (final (rawError, expectedCategory) in cases) {
          final friendly = AppMonitor.toUserFriendlyError(
            rawError,
            fallbackAction: 'save your note',
          );
          expect(
            friendly.category,
            expectedCategory,
            reason: 'Unexpected category for $rawError',
          );
          _expectZeroTechnicalWords(friendly);
        }
      },
    );

    test(
      'preserves clean, human-written form validation messages verbatim',
      () {
        const cleanPrompts = [
          'Please select a category',
          'Source and destination accounts must be different',
          'Enter a valid amount',
        ];

        for (final prompt in cleanPrompts) {
          final friendly = AppMonitor.toUserFriendlyError(prompt);
          expect(friendly.category, UserErrorCategory.input);
          expect(friendly.message, prompt);
          expect(friendly.snackbarMessage, prompt);
          expect(AppMonitor.friendlyMessage(prompt), prompt);
          _expectZeroTechnicalWords(friendly);
        }
      },
    );

    test(
      'deduplicates rapid identical user alerts within cooldown and allows distinct alerts',
      () async {
        final received = <UserFriendlyError>[];
        final sub = monitor.userAlerts.listen(received.add);
        addTearDown(sub.cancel);

        monitor.reportUserError(
          'SocketException: Failed host lookup',
          source: 'sync.1',
        );
        // Duplicate offline error immediately -> suppressed by cooldown
        monitor.reportUserError(
          'SocketException: Network is unreachable',
          source: 'sync.2',
        );
        // Different category (storage) -> delivered immediately
        monitor.reportUserError(
          'SqliteException(14): unable to open database file',
          source: 'db.save',
        );

        await Future<void>.delayed(Duration.zero);

        expect(received.length, 2);
        expect(received[0].category, UserErrorCategory.offline);
        expect(received[1].category, UserErrorCategory.storage);
        expect(
          monitor.activeUserAlert.value?.category,
          UserErrorCategory.storage,
        );

        monitor.dismissUserAlert();
        expect(monitor.activeUserAlert.value, isNull);
      },
    );

    test(
      'AppBlocObserver forwards sanitized BLoC errors and publishes jargon-free user alert',
      () {
        final previousObserver = Bloc.observer;
        Bloc.observer = AppBlocObserver(monitor: monitor);
        addTearDown(() => Bloc.observer = previousObserver);

        final cubit = _TestCounterCubit();
        cubit.triggerFailure();
        cubit.close();

        final snap = monitor.snapshot();
        expect(snap.totalErrors, 1);
        expect(snap.recentErrors.single.source, contains('_TestCounterCubit'));
        expect(
          snap.recentErrors.single.message,
          isNot(contains('mySecretToken999')),
        );
        expect(monitor.activeUserAlert.value, isNotNull);
        _expectZeroTechnicalWords(monitor.activeUserAlert.value!);
      },
    );

    testWidgets(
      'buildFallbackErrorWidget renders reassuring plain language in Light and Dark mode',
      (tester) async {
        final details = FlutterErrorDetails(
          exception: Exception('RenderFlex overflowed by 42 pixels'),
        );

        for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Center(
                  child: AppMonitor.buildFallbackErrorWidget(details),
                ),
              ),
            ),
          );

          expect(find.byType(AppText), findsWidgets);
          expect(
            find.text("This part couldn't be shown right now"),
            findsOneWidget,
          );
          expect(
            find.text(
              'Everything you saved on your device is completely safe.',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('RenderFlex'), findsNothing);
          expect(find.textContaining('Exception'), findsNothing);
        }
      },
    );

    testWidgets(
      'FeatureErrorView translates raw technical SQLite exception into friendly user guidance',
      (tester) async {
        var retried = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FeatureErrorView(
                message:
                    'CacheException: SqliteException(787): FOREIGN KEY constraint failed',
                onRetry: () => retried = true,
              ),
            ),
          ),
        );

        expect(find.textContaining('SqliteException'), findsNothing);
        expect(find.textContaining('CacheException'), findsNothing);
        expect(find.textContaining('FOREIGN KEY'), findsNothing);
        expect(find.text("Couldn't finish saving right now"), findsOneWidget);
        expect(
          find.text(
            'Your existing notes, habits, money records, and vault items remain safe.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Try Again'));
        await tester.pump();
        expect(retried, isTrue);
      },
    );

    testWidgets(
      'AppMonitorUserErrorHost shows calm user banner on unexpected error and dismisses cleanly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => AppMonitorUserErrorHost(
              monitor: monitor,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const Scaffold(body: Center(child: AppText('Home Screen'))),
          ),
        );

        expect(
          find.byKey(const ValueKey('app_user_error_banner')),
          findsNothing,
        );

        monitor.reportUserError(
          'DioException: SocketException: Failed host lookup (errno = 7)',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('app_user_error_banner')),
          findsOneWidget,
        );
        expect(find.text('You appear to be offline'), findsOneWidget);
        expect(find.textContaining('SocketException'), findsNothing);
        expect(find.textContaining('DioException'), findsNothing);

        await tester.tap(
          find.byKey(const ValueKey('dismiss_user_error_banner_btn')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('app_user_error_banner')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'SnackbarUtils.showError sanitizes raw technical crashes while keeping human prompts intact',
      (tester) async {
        late BuildContext savedCtx;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  savedCtx = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        SnackbarUtils.showError(
          savedCtx,
          'StateError: Bad state: Null check operator used on a null value',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.textContaining('StateError'), findsNothing);
        expect(find.textContaining('Null check'), findsNothing);
        expect(find.textContaining('saved items are safe'), findsOneWidget);

        ScaffoldMessenger.of(savedCtx).clearSnackBars();
        await tester.pumpAndSettle();

        SnackbarUtils.showError(savedCtx, 'Please select a category');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Please select a category'), findsOneWidget);

        ScaffoldMessenger.of(savedCtx).clearSnackBars();
        await tester.pumpAndSettle();
      },
    );
  });
}
