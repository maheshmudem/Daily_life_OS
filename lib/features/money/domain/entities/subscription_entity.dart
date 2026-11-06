import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SubscriptionEntity extends Equatable {
  final int id;
  final String name;
  final double amount;
  final String renewalDate;
  final bool autoKillEnabled;
  final int iconCodePoint;

  const SubscriptionEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.renewalDate,
    required this.autoKillEnabled,
    required this.iconCodePoint,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  String get renewalLabel {
    try {
      final dt = DateTime.parse(renewalDate);
      final now = DateTime.now();
      final diff = dt.difference(now).inDays;
      final month = _monthAbbr(dt.month);
      return '$month ${dt.day} (In $diff days)';
    } catch (_) {
      return renewalDate;
    }
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  @override
  List<Object?> get props => [id, autoKillEnabled];
}

class IouEntity extends Equatable {
  final int id;
  final String person;
  final double amount;
  final String type; // 'lent' / 'borrowed'
  final String note;
  final String date;
  final bool isSettled;

  const IouEntity({
    required this.id,
    required this.person,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    required this.isSettled,
  });

  bool get isLent => type == 'lent';
  String get typeLabel =>
      isLent ? 'Lent to (To Collect)' : 'Borrowed from (To Pay)';

  static final RegExp _dueTagRegex = RegExp(
    r'\s*\[Due:\s*(\d{4}-\d{2}-\d{2})\]\s*',
  );

  /// Formats [note] with an embedded `[Due: YYYY-MM-DD]` tag when [dueDate] is provided.
  static String formatNoteWithDueDate(String note, DateTime? dueDate) {
    final cleaned = note.replaceAll(_dueTagRegex, '').trim();
    if (dueDate == null) return cleaned;
    final iso =
        '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
    return cleaned.isEmpty ? '[Due: $iso]' : '$cleaned [Due: $iso]';
  }

  /// Note text with any `[Due: YYYY-MM-DD]` metadata stripped for display.
  String get cleanNote {
    final cleaned = note.replaceAll(_dueTagRegex, '').trim();
    return cleaned.isEmpty
        ? (isLent ? 'Money lent' : 'Money borrowed')
        : cleaned;
  }

  /// Optional due / collection date parsed from [note].
  DateTime? get dueDate {
    final match = _dueTagRegex.firstMatch(note);
    if (match == null) return null;
    return DateTime.tryParse(match.group(1)!);
  }

  bool get isOverdue {
    final due = dueDate;
    if (due == null || isSettled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }

  bool get isDueToday {
    final due = dueDate;
    if (due == null || isSettled) return false;
    final now = DateTime.now();
    return due.year == now.year && due.month == now.month && due.day == now.day;
  }

  bool get isDueSoon {
    final due = dueDate;
    if (due == null || isSettled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = due.difference(today).inDays;
    return diff >= 0 && diff <= 3;
  }

  String? get dueBadgeLabel {
    final due = dueDate;
    if (due == null) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr = '${months[due.month - 1]} ${due.day}';
    if (isOverdue) return 'Overdue • $dateStr';
    if (isDueToday) return 'Due Today • $dateStr';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = due.difference(today).inDays;
    return 'Due $dateStr (in ${diff}d)';
  }

  @override
  List<Object?> get props => [id, isSettled, note];
}
