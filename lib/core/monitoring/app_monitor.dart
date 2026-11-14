import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';
import '../error/exceptions.dart';
import '../error/failures.dart';
import '../widgets/app_text.dart';

enum MonitorSeverity { info, warning, error, critical }

enum AppHealthStatus { healthy, degraded, critical }

/// Everyday, user-centered categories used to explain an issue without any
/// technical jargon.
enum UserErrorCategory {
  offline,
  timeout,
  storage,
  permission,
  security,
  input,
  notFound,
  busy,
  unexpected,
}

/// Human-friendly error representation written strictly from the user's point
/// of view — plain words, calm reassurance, and a clear next step.
@immutable
class UserFriendlyError {
  final UserErrorCategory category;
  final String title;
  final String message;
  final String reassurance;
  final String actionHint;
  final String actionLabel;
  final String snackbarMessage;
  final IconData icon;
  final Color accentColor;
  final bool canRetry;

  const UserFriendlyError({
    required this.category,
    required this.title,
    required this.message,
    required this.reassurance,
    required this.actionHint,
    required this.actionLabel,
    required this.snackbarMessage,
    required this.icon,
    required this.accentColor,
    this.canRetry = true,
  });
}

@immutable
class MonitorBreadcrumb {
  final DateTime timestamp;
  final String category;
  final String message;
  final MonitorSeverity severity;
  final Map<String, String> metadata;

  const MonitorBreadcrumb({
    required this.timestamp,
    required this.category,
    required this.message,
    this.severity = MonitorSeverity.info,
    this.metadata = const {},
  });
}

@immutable
class MonitorErrorRecord {
  final DateTime timestamp;
  final String source;
  final String message;
  final String stackPreview;
  final bool fatal;
  final UserFriendlyError userView;

  const MonitorErrorRecord({
    required this.timestamp,
    required this.source,
    required this.message,
    required this.stackPreview,
    required this.userView,
    this.fatal = false,
  });
}

@immutable
class MonitorSpanRecord {
  final DateTime timestamp;
  final String operation;
  final int durationMs;
  final bool success;

  const MonitorSpanRecord({
    required this.timestamp,
    required this.operation,
    required this.durationMs,
    this.success = true,
  });
}

@immutable
class AppHealthSnapshot {
  final AppHealthStatus status;
  final Duration uptime;
  final int? startupDurationMs;
  final int totalErrors;
  final int fatalErrors;
  final int securityAlerts;
  final int blocTransitions;
  final int totalFrames;
  final int jankFrames;
  final int severeJankFrames;
  final double averageSpanMs;
  final List<MonitorBreadcrumb> recentBreadcrumbs;
  final List<MonitorErrorRecord> recentErrors;
  final List<MonitorSpanRecord> recentSpans;

  const AppHealthSnapshot({
    required this.status,
    required this.uptime,
    required this.startupDurationMs,
    required this.totalErrors,
    required this.fatalErrors,
    required this.securityAlerts,
    required this.blocTransitions,
    required this.totalFrames,
    required this.jankFrames,
    required this.severeJankFrames,
    required this.averageSpanMs,
    required this.recentBreadcrumbs,
    required this.recentErrors,
    required this.recentSpans,
  });

  double get jankRatio => totalFrames == 0 ? 0.0 : jankFrames / totalFrames;

  String get statusLabel => switch (status) {
    AppHealthStatus.healthy => 'Healthy',
    AppHealthStatus.degraded => 'Degraded',
    AppHealthStatus.critical => 'Attention Needed',
  };

  /// Everyday, non-technical status label for the user interface.
  String get userStatusLabel => switch (status) {
    AppHealthStatus.healthy => 'Running Smoothly',
    AppHealthStatus.degraded => 'Recovering Smoothly',
    AppHealthStatus.critical => 'Needs a Quick Refresh',
  };

  /// Warm reassurance message shown in user-facing settings.
  String get userReassuranceMessage => switch (status) {
    AppHealthStatus.healthy =>
      'Everything in your workspace is saved safely on this device.',
    AppHealthStatus.degraded =>
      'A few small hiccups were handled automatically. Your saved items are safe.',
    AppHealthStatus.critical =>
      'Your saved notes, habits, money records, and vault are safe. Reopening the app can refresh everything.',
  };

  /// Plain-language summary safe to read and share by any everyday user, with
  /// zero technical jargon or code terms.
  String toUserSupportSummary() {
    final activeMinutes = uptime.inMinutes;
    final sessionLabel = activeMinutes < 1
        ? 'Less than a minute'
        : '$activeMinutes min';
    final buf = StringBuffer()
      ..writeln('═══════════════════════════════════════════')
      ..writeln('  DAILY LIFE OS — APP CARE & SUPPORT SUMMARY')
      ..writeln('═══════════════════════════════════════════')
      ..writeln('App Smoothness  : $userStatusLabel')
      ..writeln('Session Time    : $sessionLabel')
      ..writeln('Saved Data      : Safe on your device')
      ..writeln(
        'Vault Lock      : ${securityAlerts == 0 ? "Protected" : "Extra protection active"}',
      )
      ..writeln(
        'Recent Hiccups  : ${totalErrors == 0 ? "None" : "$totalErrors handled safely"}',
      );

    if (recentErrors.isNotEmpty) {
      buf.writeln('─── Recent Notes for Support ───');
      for (final err in recentErrors.reversed.take(3)) {
        buf.writeln('• ${err.userView.title}: ${err.userView.message}');
      }
    }

    buf
      ..writeln('───────────────────────────────────────────')
      ..writeln(userReassuranceMessage)
      ..writeln('═══════════════════════════════════════════');
    return buf.toString();
  }

  /// Internal sanitized engineering diagnostics for automated test suites.
  String toDiagnosticReport() {
    final buf = StringBuffer()
      ..writeln('═══════════════════════════════════════════')
      ..writeln('  DAILY LIFE OS — PRODUCTION DIAGNOSTICS')
      ..writeln('═══════════════════════════════════════════')
      ..writeln('Health Status   : $statusLabel')
      ..writeln('Uptime          : ${uptime.inSeconds}s')
      ..writeln(
        'Cold Boot       : ${startupDurationMs != null ? "${startupDurationMs}ms" : "n/a"}',
      )
      ..writeln('Uncaught Errors : $totalErrors (fatal: $fatalErrors)')
      ..writeln('Security Alerts : $securityAlerts')
      ..writeln('BLoC Events     : $blocTransitions')
      ..writeln(
        'Frame Telemetry : $totalFrames frames • $jankFrames jank (${(jankRatio * 100).toStringAsFixed(1)}%)',
      )
      ..writeln('Avg Span Time   : ${averageSpanMs.toStringAsFixed(1)}ms');

    if (recentErrors.isNotEmpty) {
      buf.writeln('─── Recent Sanitized Errors ───');
      for (final err in recentErrors.reversed.take(5)) {
        buf.writeln(
          '[${err.timestamp.toIso8601String()}] (${err.source}) ${err.message}',
        );
      }
    }

    if (recentBreadcrumbs.isNotEmpty) {
      buf.writeln('─── Recent Telemetry Breadcrumbs ───');
      for (final crumb in recentBreadcrumbs.reversed.take(8)) {
        buf.writeln(
          '[${crumb.severity.name.toUpperCase()}] ${crumb.category}: ${crumb.message}',
        );
      }
    }

    buf.writeln('═══════════════════════════════════════════');
    return buf.toString();
  }
}

/// Dual-layer observability & user-experience error monitor:
/// - **Internal layer**: Captures sanitized telemetry, frame timings, spans,
///   and security events with bounded O(1) ring buffers and secret redaction.
/// - **User-facing layer**: Translates every raw error into calm, plain
///   everyday language from the user's point of view — zero technical words.
class AppMonitor {
  static final AppMonitor instance = AppMonitor();

  final int maxBreadcrumbs;
  final int maxErrors;
  final int maxSpans;
  final Duration alertCooldown;

  final DateTime _startedAt;
  final ListQueue<MonitorBreadcrumb> _breadcrumbs =
      ListQueue<MonitorBreadcrumb>();
  final ListQueue<MonitorErrorRecord> _errors = ListQueue<MonitorErrorRecord>();
  final ListQueue<MonitorSpanRecord> _spans = ListQueue<MonitorSpanRecord>();

  final StreamController<UserFriendlyError> _userAlertController =
      StreamController<UserFriendlyError>.broadcast();
  final ValueNotifier<UserFriendlyError?> _activeUserAlert =
      ValueNotifier<UserFriendlyError?>(null);

  DateTime? _lastUserAlertAt;
  UserErrorCategory? _lastUserAlertCategory;
  String? _lastUserAlertTitle;

  int? _startupDurationMs;
  int _totalErrors = 0;
  int _fatalErrors = 0;
  int _securityAlerts = 0;
  int _blocTransitions = 0;
  int _totalFrames = 0;
  int _jankFrames = 0;
  int _severeJankFrames = 0;
  bool _frameObserverAttached = false;

  AppMonitor({
    this.maxBreadcrumbs = 200,
    this.maxErrors = 50,
    this.maxSpans = 100,
    this.alertCooldown = const Duration(seconds: 4),
    DateTime? startedAt,
  }) : _startedAt = startedAt ?? DateTime.now();

  /// Stream of deduplicated, plain-language user error notifications.
  Stream<UserFriendlyError> get userAlerts => _userAlertController.stream;

  /// Currently active floating user alert (observed by `AppMonitorUserErrorHost`).
  ValueListenable<UserFriendlyError?> get activeUserAlert => _activeUserAlert;

  /// Dismisses the active user-facing recovery alert.
  void dismissUserAlert() {
    _activeUserAlert.value = null;
  }

  static final RegExp _bearerRegex = RegExp(
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  static final RegExp _jwtRegex = RegExp(
    r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
  );

  static final RegExp _jsonSecretRegex = RegExp(
    r'''(["']?(?:password|passwd|pwd|pin|decoyPin|decoy_pin|pattern|decoyPattern|secret|token|access_token|refresh_token|api_key|apikey|authorization|cvv|card_number|cardNumber|otp)["']?\s*[:=]\s*)(?:"[^"]*"|'[^']*'|[^\s,&}\]]+)''',
    caseSensitive: false,
  );

  static final RegExp _querySecretRegex = RegExp(
    r'([?&](?:token|access_token|refresh_token|api_key|apikey|password|pin|secret|otp)=)[^&\s]+',
    caseSensitive: false,
  );

  static final RegExp _cardPanRegex = RegExp(r'\b(?:\d[ -]*?){13,19}\b');

  /// Detects developer/system jargon so technical terms never reach the user.
  static final RegExp _technicalJargonRegex = RegExp(
    r'('
    r'exception|stack\s*trace|sqlite|drift|sql\b|database|db\s+closed|'
    r'foreign\s+key|constraint|dio\b|socket|host\s+lookup|errno|'
    r'status\s*code|http\b|https?://|\b(?:400|401|403|404|408|422|429|500|502|503|504)\b|'
    r'null\s+check|null\s+value|null\s+subtype|\bnull\b|is\s+not\s+a\s+subtype|'
    r'state\s*error|bad\s+state|range\s*error|type\s*error|format\s*error|'
    r'assertion\s*error|argument\s*error|unsupported\s*error|unimplemented\s*error|'
    r'late\s*initialization|no\s*such\s*method|platform\s*exception|channel-error|'
    r'file\s*system\s*exception|os\s+error|xmlhttprequest|client\s*exception|'
    r'cache\s*failure|server\s*failure|network\s*failure|validation\s*failure|'
    r'\bfailure\s*\(|^error\s*:|\berror\s*code\b|json\b|serializ|deserializ|'
    r'\bbloc\b|\bcubit\b|telemetry|\bspan\b|renderflex|renderbox|overflowed\s+by|'
    r'flutter\s*error|package:|dart:|0x[0-9a-f]+|\[redacted|\{\s*"|#0\s+'
    r')',
    caseSensitive: false,
  );

  /// Scrubs tokens, passwords, PINs, API keys, and payment card numbers from
  /// logs, error messages, and telemetry payloads.
  static String redact(String input) {
    if (input.isEmpty) return input;
    var sanitized = input;
    if (sanitized.length > 4096) {
      sanitized = '${sanitized.substring(0, 4096)}...[TRUNCATED]';
    }
    sanitized = sanitized.replaceAll(_bearerRegex, 'Bearer [REDACTED]');
    sanitized = sanitized.replaceAll(_jwtRegex, '[REDACTED_JWT]');
    sanitized = sanitized.replaceAllMapped(
      _querySecretRegex,
      (m) => '${m.group(1)}[REDACTED]',
    );
    sanitized = sanitized.replaceAllMapped(
      _jsonSecretRegex,
      (m) => '${m.group(1)}"[REDACTED]"',
    );
    sanitized = sanitized.replaceAll(_cardPanRegex, '[REDACTED_CARD]');
    return sanitized;
  }

  /// Returns `true` if [text] contains technical developer/runtime terms that
  /// should never be displayed directly to a user.
  static bool containsTechnicalJargon(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return _technicalJargonRegex.hasMatch(trimmed);
  }

  /// Returns a concise, single-sentence message from the user's point of view,
  /// suitable for inline banners and snackbars.
  static String friendlyMessage(Object? error, {String? fallbackAction}) {
    return toUserFriendlyError(
      error,
      fallbackAction: fallbackAction,
    ).snackbarMessage;
  }

  /// Converts any raw [error] (`Exception`, `Failure`, `FlutterErrorDetails`,
  /// `String`, or runtime crash) into a warm, plain-language [UserFriendlyError]
  /// written entirely from the user's perspective.
  static UserFriendlyError toUserFriendlyError(
    Object? error, {
    String? fallbackAction,
  }) {
    if (error is UserFriendlyError) return error;

    if (error is FlutterErrorDetails) {
      return const UserFriendlyError(
        category: UserErrorCategory.unexpected,
        title: "This part couldn't be shown right now",
        message:
            'We hit a small display hiccup here, so we paused this card safely.',
        reassurance: 'Everything you saved on your device is completely safe.',
        actionHint: 'Switch tabs or reopen this screen to refresh the view.',
        actionLabel: 'Try Again',
        snackbarMessage:
            "This view hit a small hiccup, but your saved items are safe.",
        icon: Icons.auto_awesome_mosaic_outlined,
        accentColor: AppColors.warning,
      );
    }

    // 1. Typed domain failures & exceptions
    if (error is ValidationFailure) {
      return _buildInputError(error.message);
    }
    if (error is ValidationException) {
      return _buildInputError(error.message);
    }
    if (error is NetworkFailure || error is NetworkException) {
      return _offlineError();
    }
    if (error is TimeoutException) {
      return _timeoutError();
    }
    if (error is CacheFailure || error is CacheException) {
      return _storageError(fallbackAction: fallbackAction);
    }
    if (error is ServerFailure) {
      return _classifyByKeywords(
        error.message,
        fallbackAction: fallbackAction,
        preferServiceFallback: true,
      );
    }
    if (error is ServerException) {
      final code = error.statusCode;
      if (code == 401 || code == 403) return _securityError();
      if (code == 404) return _notFoundError();
      if (code == 408) return _timeoutError();
      if (code == 429) return _busyError();
      return _serviceSnagError(fallbackAction: fallbackAction);
    }

    if (error == null) {
      return _unexpectedError(fallbackAction: fallbackAction);
    }

    // 2. Clean, already-human user guidance pass-through (e.g. "Please select a category")
    if (error is String) {
      final trimmed = error.trim();
      if (trimmed.isEmpty) {
        return _unexpectedError(fallbackAction: fallbackAction);
      }
      final lower = trimmed.toLowerCase();
      final isGenericPlaceholder =
          lower == 'something went wrong' ||
          lower == 'something went wrong.' ||
          lower == 'something went wrong. please try again.' ||
          lower == 'an unexpected error occurred. please try again.';

      if (!isGenericPlaceholder &&
          trimmed.length <= 140 &&
          !containsTechnicalJargon(trimmed)) {
        // Still route explicit offline user strings to the offline card icon/title
        if (lower.contains('no internet') || lower.contains('offline')) {
          return _offlineError();
        }
        return UserFriendlyError(
          category: UserErrorCategory.input,
          title: 'Just one quick check',
          message: trimmed,
          reassurance: 'Nothing you saved was changed or lost.',
          actionHint: 'Adjust the detail above and try again.',
          actionLabel: 'Try Again',
          snackbarMessage: trimmed,
          icon: Icons.info_outline_rounded,
          accentColor: AppColors.info,
          canRetry: false,
        );
      }
    }

    return _classifyByKeywords(
      error.toString(),
      fallbackAction: fallbackAction,
    );
  }

  static UserFriendlyError _classifyByKeywords(
    String raw, {
    String? fallbackAction,
    bool preferServiceFallback = false,
  }) {
    final lower = raw.toLowerCase();

    // Connection / Offline
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('connection error') ||
        lower.contains('no internet') ||
        lower.contains('offline') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('clientexception')) {
      return _offlineError();
    }

    // Slow response / Timeout
    if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('deadline exceeded') ||
        lower.contains('408')) {
      return _timeoutError();
    }

    // Device permissions (camera, mic, notifications, photos)
    if (lower.contains('permission') ||
        lower.contains('access_denied') ||
        lower.contains('access denied') ||
        lower.contains('camera') && lower.contains('denied') ||
        lower.contains('microphone') && lower.contains('denied') ||
        lower.contains('not authorized to use')) {
      return _permissionError();
    }

    // Vault / Authentication / Lockout
    if (lower.contains('lockout') ||
        lower.contains('unauthorized') ||
        lower.contains('unauthenticated') ||
        lower.contains('session expired') ||
        lower.contains('forbidden') ||
        RegExp(r'\b(401|403)\b').hasMatch(lower)) {
      return _securityError();
    }

    // Missing / Removed item
    if (lower.contains('not found') ||
        lower.contains('does not exist') ||
        lower.contains('missing file') ||
        lower.contains('no element') ||
        RegExp(r'\b404\b').hasMatch(lower)) {
      return _notFoundError();
    }

    // Busy / Rate limit
    if (lower.contains('too many requests') ||
        lower.contains('too many attempts') ||
        lower.contains('rate limit') ||
        lower.contains('overloaded') ||
        RegExp(r'\b429\b').hasMatch(lower)) {
      return _busyError();
    }

    // Local device storage / saving & loading
    if (lower.contains('sqlite') ||
        lower.contains('drift') ||
        lower.contains('database') ||
        lower.contains('db closed') ||
        lower.contains('foreign key') ||
        lower.contains('constraint') ||
        lower.contains('cache') ||
        lower.contains('filesystem') ||
        lower.contains('disk') ||
        lower.contains('storage')) {
      return _storageError(fallbackAction: fallbackAction);
    }

    // Entry / formatting issue
    if (lower.contains('formatexception') ||
        lower.contains('invalid radix') ||
        lower.contains('unexpected character')) {
      return _buildInputError('');
    }

    if (preferServiceFallback ||
        RegExp(r'\b(500|502|503|504)\b').hasMatch(lower)) {
      return _serviceSnagError(fallbackAction: fallbackAction);
    }

    return _unexpectedError(fallbackAction: fallbackAction);
  }

  static UserFriendlyError _buildInputError(String rawMessage) {
    final trimmed = rawMessage.trim();
    final safeBody =
        trimmed.isNotEmpty &&
            trimmed.length <= 140 &&
            !containsTechnicalJargon(trimmed)
        ? trimmed
        : 'Please double-check what you entered and try again.';
    return UserFriendlyError(
      category: UserErrorCategory.input,
      title: 'Please check your details',
      message: safeBody,
      reassurance: 'Nothing you saved earlier was changed.',
      actionHint: 'Review the fields above and try again.',
      actionLabel: 'Got It',
      snackbarMessage: safeBody,
      icon: Icons.info_outline_rounded,
      accentColor: AppColors.info,
      canRetry: false,
    );
  }

  static UserFriendlyError _offlineError() {
    return const UserFriendlyError(
      category: UserErrorCategory.offline,
      title: 'You appear to be offline',
      message: "We couldn't reach the internet right now, so this step paused.",
      reassurance:
          'Your saved habits, notes, planner, money records, and vault work safely offline.',
      actionHint: 'Check your Wi-Fi or mobile data and try again.',
      actionLabel: 'Try Again',
      snackbarMessage:
          "You're offline right now. Check your internet connection and try again.",
      icon: Icons.wifi_off_rounded,
      accentColor: AppColors.info,
    );
  }

  static UserFriendlyError _timeoutError() {
    return const UserFriendlyError(
      category: UserErrorCategory.timeout,
      title: 'Taking longer than usual',
      message: 'This is taking a little longer than expected to finish.',
      reassurance: 'Everything already saved on your phone is safe.',
      actionHint: 'Wait a moment and tap Try Again.',
      actionLabel: 'Try Again',
      snackbarMessage:
          'That took a bit too long. Please wait a moment and try again.',
      icon: Icons.schedule_rounded,
      accentColor: AppColors.warning,
    );
  }

  static UserFriendlyError _storageError({String? fallbackAction}) {
    final actionPhrase =
        fallbackAction != null && fallbackAction.trim().isNotEmpty
        ? fallbackAction.trim()
        : 'load or save your changes';
    return UserFriendlyError(
      category: UserErrorCategory.storage,
      title: "Couldn't finish saving right now",
      message:
          "We ran into a brief hiccup trying to $actionPhrase on your device.",
      reassurance:
          'Your existing notes, habits, money records, and vault items remain safe.',
      actionHint:
          'Tap Try Again. Freeing a little phone storage can also help if space is low.',
      actionLabel: 'Try Again',
      snackbarMessage:
          "Couldn't $actionPhrase just now. Your saved items are safe — please try again.",
      icon: Icons.folder_off_outlined,
      accentColor: AppColors.warning,
    );
  }

  static UserFriendlyError _permissionError() {
    return const UserFriendlyError(
      category: UserErrorCategory.permission,
      title: 'Permission needed to continue',
      message:
          'This feature needs your permission on your phone (such as camera, microphone, or alerts) before it can work.',
      reassurance: 'Your privacy choices always stay in your control.',
      actionHint:
          'Turn on permission in your phone Settings if you want to use this.',
      actionLabel: 'Try Again',
      snackbarMessage:
          'Please allow access in your phone Settings to use this feature.',
      icon: Icons.privacy_tip_outlined,
      accentColor: AppColors.info,
    );
  }

  static UserFriendlyError _securityError() {
    return const UserFriendlyError(
      category: UserErrorCategory.security,
      title: 'Quick verification needed',
      message:
          'For your privacy, please unlock or verify again before continuing.',
      reassurance: 'Your private items remain safely protected.',
      actionHint: 'Check your PIN or unlock method and try again.',
      actionLabel: 'Try Again',
      snackbarMessage: 'Please unlock or verify again to continue safely.',
      icon: Icons.lock_person_outlined,
      accentColor: AppColors.moduleVault,
    );
  }

  static UserFriendlyError _notFoundError() {
    return const UserFriendlyError(
      category: UserErrorCategory.notFound,
      title: 'Item no longer here',
      message:
          "We couldn't find that item — it may have already been moved or deleted.",
      reassurance: 'Everything else in your workspace is untouched.',
      actionHint: 'Refresh the screen to view your latest list.',
      actionLabel: 'Refresh',
      snackbarMessage:
          'That item may have already been moved or removed. Try refreshing.',
      icon: Icons.search_off_rounded,
      accentColor: AppColors.info,
    );
  }

  static UserFriendlyError _busyError() {
    return const UserFriendlyError(
      category: UserErrorCategory.busy,
      title: 'Just a moment please',
      message:
          'A lot happened at once, so we paused briefly to keep everything smooth.',
      reassurance: 'Nothing you saved was lost.',
      actionHint: 'Wait a few seconds and try again.',
      actionLabel: 'Try Again',
      snackbarMessage:
          'Give it a few seconds and try again — your data is safe.',
      icon: Icons.hourglass_bottom_rounded,
      accentColor: AppColors.warning,
    );
  }

  static UserFriendlyError _serviceSnagError({String? fallbackAction}) {
    final actionPhrase =
        fallbackAction != null && fallbackAction.trim().isNotEmpty
        ? fallbackAction.trim()
        : 'complete that request';
    return UserFriendlyError(
      category: UserErrorCategory.unexpected,
      title: 'Temporarily unavailable',
      message:
          "We couldn't $actionPhrase right now because the service is taking a short break.",
      reassurance: 'All of your saved items on this device are safe.',
      actionHint: 'Please try again in a few moments.',
      actionLabel: 'Try Again',
      snackbarMessage:
          "Couldn't $actionPhrase right now. Your saved data is safe — try again shortly.",
      icon: Icons.cloud_off_rounded,
      accentColor: AppColors.warning,
    );
  }

  static UserFriendlyError _unexpectedError({String? fallbackAction}) {
    final actionPhrase =
        fallbackAction != null && fallbackAction.trim().isNotEmpty
        ? 'while trying to ${fallbackAction.trim()}'
        : 'just now';
    return UserFriendlyError(
      category: UserErrorCategory.unexpected,
      title: 'We hit a small snag',
      message: "Something didn't finish as expected $actionPhrase.",
      reassurance:
          'Your saved habits, notes, money records, and vault items are safe.',
      actionHint: 'Please try again in a moment.',
      actionLabel: 'Try Again',
      snackbarMessage:
          "We hit a small snag $actionPhrase. Your saved items are safe — please try again.",
      icon: Icons.spa_outlined,
      accentColor: AppColors.warning,
    );
  }

  /// Installs global Flutter & PlatformDispatcher uncaught error boundaries.
  void installGlobalErrorHandlers({
    bool installReleaseErrorWidget = kReleaseMode,
  }) {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      recordError(
        details.exception,
        details.stack,
        source: 'flutter_framework',
        fatal: !details.silent,
      );
      if (kDebugMode) {
        if (previousFlutterHandler != null) {
          previousFlutterHandler(details);
        } else {
          FlutterError.presentError(details);
        }
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(
        error,
        stack,
        source: 'platform_dispatcher',
        fatal: true,
        notifyUser: true,
      );
      return true;
    };

    if (installReleaseErrorWidget) {
      ErrorWidget.builder = buildFallbackErrorWidget;
    }
  }

  /// Calm, human-readable fallback widget rendered if an unexpected display
  /// hiccup occurs — never shows red screens or technical jargon.
  static Widget buildFallbackErrorWidget(FlutterErrorDetails details) {
    final friendly = toUserFriendlyError(details);
    return Builder(
      builder: (context) {
        final palette = context.palette;
        return Material(
          color: palette.card,
          borderRadius: AppRadius.radiusMd,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: friendly.accentColor.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    friendly.icon,
                    color: friendly.accentColor,
                    size: 17,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleSmall(
                        friendly.title,
                        color: palette.heading,
                      ),
                      const SizedBox(height: 2),
                      AppText.bodySmall(friendly.message, color: palette.body),
                      const SizedBox(height: 4),
                      AppText.caption(
                        friendly.reassurance,
                        color: palette.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Attaches a `SchedulerBinding` frame timings listener to detect UI jank.
  void attachFrameTimingObserver() {
    if (_frameObserverAttached) return;
    try {
      SchedulerBinding.instance.addTimingsCallback(handleFrameTimings);
      _frameObserverAttached = true;
    } catch (_) {
      // Safe no-op if binding is not yet initialized.
    }
  }

  /// Detaches the frame timings listener cleanly.
  void detachFrameTimingObserver() {
    if (!_frameObserverAttached) return;
    try {
      SchedulerBinding.instance.removeTimingsCallback(handleFrameTimings);
    } catch (_) {}
    _frameObserverAttached = false;
  }

  @visibleForTesting
  void handleFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _totalFrames++;
      final totalMs = timing.totalSpan.inMilliseconds;
      if (totalMs > 16) {
        _jankFrames++;
      }
      if (totalMs > 32) {
        _severeJankFrames++;
      }
    }
  }

  /// Records frame render duration in milliseconds (useful in tests & custom benchmarks).
  void recordFrameDurationMs(int totalSpanMs) {
    _totalFrames++;
    if (totalSpanMs > 16) {
      _jankFrames++;
    }
    if (totalSpanMs > 32) {
      _severeJankFrames++;
    }
  }

  void recordStartupDuration(Duration duration) {
    _startupDurationMs = duration.inMilliseconds;
    recordBreadcrumb(
      category: 'lifecycle',
      message: 'Cold startup completed in ${duration.inMilliseconds}ms',
    );
  }

  void recordBlocTransition(String blocName, String eventName) {
    _blocTransitions++;
    if (kDebugMode) {
      developer.log(
        '$blocName -> ${redact(eventName)}',
        name: 'DailyLifeOS.Bloc',
      );
    }
  }

  void recordBreadcrumb({
    required String category,
    required String message,
    MonitorSeverity severity = MonitorSeverity.info,
    Map<String, Object?>? metadata,
  }) {
    final sanitizedMeta = <String, String>{};
    if (metadata != null) {
      for (final entry in metadata.entries) {
        sanitizedMeta[entry.key] = redact('${entry.value ?? ''}');
      }
    }
    _pushBounded(
      _breadcrumbs,
      MonitorBreadcrumb(
        timestamp: DateTime.now(),
        category: category,
        message: redact(message),
        severity: severity,
        metadata: sanitizedMeta,
      ),
      maxBreadcrumbs,
    );
  }

  void recordSecurityEvent(
    String action, {
    bool blocked = false,
    String? detail,
  }) {
    if (blocked) {
      _securityAlerts++;
    }
    recordBreadcrumb(
      category: 'security',
      message: detail != null ? '$action ($detail)' : action,
      severity: blocked ? MonitorSeverity.warning : MonitorSeverity.info,
    );
  }

  /// Records a technical error internally (with full secret redaction) AND
  /// publishes a deduplicated, plain-English [UserFriendlyError] alert for the
  /// user interface.
  UserFriendlyError reportUserError(
    Object error, {
    StackTrace? stackTrace,
    String source = 'user_action',
    String? fallbackAction,
  }) {
    final friendly = toUserFriendlyError(error, fallbackAction: fallbackAction);
    recordError(
      error,
      stackTrace,
      source: source,
      notifyUser: true,
      fallbackAction: fallbackAction,
    );
    return friendly;
  }

  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String source = 'runtime',
    bool fatal = false,
    bool notifyUser = false,
    String? fallbackAction,
  }) {
    _totalErrors++;
    if (fatal) {
      _fatalErrors++;
    }
    final safeMessage = redact(error.toString());
    final rawStack = stackTrace?.toString() ?? '';
    final stackLines = rawStack.split('\n').take(6).join('\n');
    final safeStack = redact(stackLines);
    final friendly = toUserFriendlyError(error, fallbackAction: fallbackAction);

    _pushBounded(
      _errors,
      MonitorErrorRecord(
        timestamp: DateTime.now(),
        source: source,
        message: safeMessage,
        stackPreview: safeStack,
        userView: friendly,
        fatal: fatal,
      ),
      maxErrors,
    );

    recordBreadcrumb(
      category: 'error.$source',
      message: safeMessage,
      severity: fatal ? MonitorSeverity.critical : MonitorSeverity.error,
    );

    if (notifyUser) {
      _emitUserAlertIfNotCooledDown(friendly);
    }

    if (kDebugMode) {
      developer.log(
        '[$source] $safeMessage',
        name: 'DailyLifeOS.Monitor',
        level: fatal ? 1200 : 1000,
      );
    }
  }

  void _emitUserAlertIfNotCooledDown(UserFriendlyError friendly) {
    final now = DateTime.now();
    if (_lastUserAlertAt != null &&
        _lastUserAlertCategory == friendly.category &&
        _lastUserAlertTitle == friendly.title &&
        now.difference(_lastUserAlertAt!) < alertCooldown) {
      return;
    }
    _lastUserAlertAt = now;
    _lastUserAlertCategory = friendly.category;
    _lastUserAlertTitle = friendly.title;
    _activeUserAlert.value = friendly;
    if (!_userAlertController.isClosed) {
      _userAlertController.add(friendly);
    }
  }

  void recordSpan(String operation, Duration duration, {bool success = true}) {
    _pushBounded(
      _spans,
      MonitorSpanRecord(
        timestamp: DateTime.now(),
        operation: redact(operation),
        durationMs: duration.inMilliseconds,
        success: success,
      ),
      maxSpans,
    );
  }

  Future<T> traceAsync<T>(String operation, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    try {
      final result = await action();
      sw.stop();
      recordSpan(operation, sw.elapsed, success: true);
      return result;
    } catch (e, st) {
      sw.stop();
      recordSpan(operation, sw.elapsed, success: false);
      recordError(e, st, source: operation);
      rethrow;
    }
  }

  T traceSync<T>(String operation, T Function() action) {
    final sw = Stopwatch()..start();
    try {
      final result = action();
      sw.stop();
      recordSpan(operation, sw.elapsed, success: true);
      return result;
    } catch (e, st) {
      sw.stop();
      recordSpan(operation, sw.elapsed, success: false);
      recordError(e, st, source: operation);
      rethrow;
    }
  }

  AppHealthSnapshot snapshot() {
    final status = _fatalErrors > 0
        ? AppHealthStatus.critical
        : (_totalErrors > 3 || _securityAlerts > 2)
        ? AppHealthStatus.degraded
        : AppHealthStatus.healthy;

    double avgSpan = 0.0;
    if (_spans.isNotEmpty) {
      final totalMs = _spans.fold<int>(0, (sum, s) => sum + s.durationMs);
      avgSpan = totalMs / _spans.length;
    }

    return AppHealthSnapshot(
      status: status,
      uptime: DateTime.now().difference(_startedAt),
      startupDurationMs: _startupDurationMs,
      totalErrors: _totalErrors,
      fatalErrors: _fatalErrors,
      securityAlerts: _securityAlerts,
      blocTransitions: _blocTransitions,
      totalFrames: _totalFrames,
      jankFrames: _jankFrames,
      severeJankFrames: _severeJankFrames,
      averageSpanMs: avgSpan,
      recentBreadcrumbs: List<MonitorBreadcrumb>.unmodifiable(_breadcrumbs),
      recentErrors: List<MonitorErrorRecord>.unmodifiable(_errors),
      recentSpans: List<MonitorSpanRecord>.unmodifiable(_spans),
    );
  }

  void reset() {
    _breadcrumbs.clear();
    _errors.clear();
    _spans.clear();
    _startupDurationMs = null;
    _totalErrors = 0;
    _fatalErrors = 0;
    _securityAlerts = 0;
    _blocTransitions = 0;
    _totalFrames = 0;
    _jankFrames = 0;
    _severeJankFrames = 0;
    _lastUserAlertAt = null;
    _lastUserAlertCategory = null;
    _lastUserAlertTitle = null;
    _activeUserAlert.value = null;
  }

  static void _pushBounded<T>(ListQueue<T> queue, T item, int maxItems) {
    if (maxItems <= 0) return;
    while (queue.length >= maxItems) {
      queue.removeFirst();
    }
    queue.addLast(item);
  }
}
