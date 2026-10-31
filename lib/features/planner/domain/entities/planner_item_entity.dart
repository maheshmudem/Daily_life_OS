import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ChecklistItem extends Equatable {
  final String id;
  final String title;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  ChecklistItem copyWith({String? id, String? title, bool? isDone}) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, isDone];
}

class PlannerItemEntity extends Equatable {
  final int id;
  final String title;
  final String date; // Start / From date (ISO8601 string)
  final String? startTime;
  final String? endTime;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final bool isDone;
  final String notes;
  final String repeatType; // 'none', 'daily', 'weekdays', 'weekly', 'monthly'
  final String repeatDays; // e.g. '1,3,5' for Mon, Wed, Fri
  final String? endDate; // ISO8601 string or null (forever)
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final int reminderOffsetMinutes; // 0, 5, 15, 30, 60, 1440
  final List<ChecklistItem> checklist;
  final String
  completedDates; // Comma-separated ISO dates: '2026-10-24,2026-10-25'

  const PlannerItemEntity({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    required this.isDone,
    required this.notes,
    this.repeatType = 'none',
    this.repeatDays = '',
    this.endDate,
    this.priority = 'medium',
    this.reminderOffsetMinutes = 0,
    this.checklist = const [],
    this.completedDates = '',
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  String get timeRange {
    if (startTime != null && endTime != null) return '$startTime – $endTime';
    if (startTime != null) return startTime!;
    return '';
  }

  String get dateDisplay {
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diff = itemDay.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  bool get isRecurring => repeatType != 'none' && repeatType.isNotEmpty;

  bool get isOverdue {
    if (isDone || isRecurring) return false;
    final dt = DateTime.tryParse(date);
    if (dt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    return itemDay.isBefore(today);
  }

  bool get isToday {
    final dt = DateTime.tryParse(date);
    if (dt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    return itemDay.isAtSameMomentAs(today);
  }

  bool get isUpcoming {
    if (isRecurring) return false;
    final dt = DateTime.tryParse(date);
    if (dt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    return itemDay.isAfter(today);
  }

  List<int> get parsedRepeatDays {
    if (repeatDays.isEmpty) return const [];
    return repeatDays
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
  }

  String get recurrenceSummary {
    switch (repeatType) {
      case 'daily':
        return endDate != null ? 'Daily until $endDate' : 'Repeats daily';
      case 'weekdays':
        return endDate != null
            ? 'Mon–Fri until $endDate'
            : 'Every weekday (Mon–Fri)';
      case 'weekly':
        final days = parsedRepeatDays;
        final names = days
            .map((d) {
              switch (d) {
                case 1:
                  return 'Mon';
                case 2:
                  return 'Tue';
                case 3:
                  return 'Wed';
                case 4:
                  return 'Thu';
                case 5:
                  return 'Fri';
                case 6:
                  return 'Sat';
                case 7:
                  return 'Sun';
                default:
                  return '';
              }
            })
            .where((n) => n.isNotEmpty)
            .join(', ');
        return names.isNotEmpty ? 'Weekly ($names)' : 'Weekly';
      case 'monthly':
        return endDate != null ? 'Monthly until $endDate' : 'Repeats monthly';
      case 'none':
      default:
        return '';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFDC2626); // Red
      case 'high':
        return const Color(0xFFF97316); // Tangerine/Orange
      case 'medium':
        return const Color(0xFF6366F1); // Indigo
      case 'low':
      default:
        return const Color(0xFF10B981); // Emerald
    }
  }

  int get checklistDoneCount => checklist.where((c) => c.isDone).length;

  static List<ChecklistItem> parseChecklistJson(String raw) {
    if (raw.trim().isEmpty || raw == '[]') return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => ChecklistItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  static String serializeChecklist(List<ChecklistItem> items) {
    return jsonEncode(items.map((i) => i.toJson()).toList());
  }

  @override
  List<Object?> get props => [
    id,
    title,
    date,
    startTime,
    endTime,
    category,
    colorValue,
    iconCodePoint,
    isDone,
    notes,
    repeatType,
    repeatDays,
    endDate,
    priority,
    reminderOffsetMinutes,
    checklist,
    completedDates,
  ];
}
