import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }

  /// Transaction row label: `Today · 9:05 AM`, `Yesterday · 6:30 PM`,
  /// `Jul 24 · 4:45 PM`.
  static String formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(day).inDays;
    final time = DateFormat('h:mm a').format(date);
    if (diffDays == 0) return 'Today · $time';
    if (diffDays == 1) return 'Yesterday · $time';
    return '${DateFormat('MMM d').format(date)} · $time';
  }

  /// Day group header for lists: `Today`, `Yesterday`, `Mon, 24 Jul`.
  static String formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(day).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(date);
  }

  /// Long form date for pickers: `July 26, 2026`.
  static String formatLongDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// `July 2026`.
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// `Jul`.
  static String formatMonthShort(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Exclusive end (first instant of next month).
  static DateTime startOfNextMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 1);

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  static String formatDisplayDate(String? isoString) {
    if (isoString == null) return '—';
    final date = parseDate(isoString);
    if (date == null) return '—';
    return formatDate(date);
  }
}
