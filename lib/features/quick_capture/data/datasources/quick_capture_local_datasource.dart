import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../today_hub/domain/entities/habit_entity.dart';
import '../../../today_hub/domain/usecases/manage_habits_usecase.dart';
import '../../domain/entities/quick_capture_entities.dart';

/// Writes Quick Capture items to local storage.
///
/// Every method **throws** [CacheException] when the write fails; it never
/// swallows errors. Mapping to `Failure` happens in the repository.
abstract class QuickCaptureLocalDataSource {
  Future<void> insertTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    required String paymentMode,
    required QuickCaptureMode source,
  });

  Future<void> insertReminder({
    required String title,
    required DateTime date,
    required String time,
    required String priority,
    required String category,
    required bool addToTodayTimeline,
    required DateTime? notifyAt,
    required QuickCaptureMode source,
  });

  Future<void> insertHabit({required String title, required String category});

  Future<void> insertNote({
    required String title,
    required String content,
    required String tag,
    required bool isPinned,
  });
}

class QuickCaptureLocalDataSourceImpl implements QuickCaptureLocalDataSource {
  final AppDatabase _db;
  final AddHabitUseCase _addHabit;
  final NotificationService _notifications;

  const QuickCaptureLocalDataSourceImpl({
    required AppDatabase database,
    required AddHabitUseCase addHabitUseCase,
    required NotificationService notificationService,
  }) : _db = database,
       _addHabit = addHabitUseCase,
       _notifications = notificationService;

  String _sourceNote(QuickCaptureMode source) =>
      'Captured via ${source.name.toUpperCase()}';

  Future<void> _write(String what, Future<void> Function() action) async {
    try {
      await action();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(message: 'Failed to save $what: $e');
    }
  }

  @override
  Future<void> insertTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    required String paymentMode,
    required QuickCaptureMode source,
  }) {
    return _write('transaction', () async {
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              title: title,
              category: category,
              amount: amount,
              mode: paymentMode,
              iconCodePoint: isIncome
                  ? Icons.south_west_rounded.codePoint
                  : Icons.bolt_rounded.codePoint,
              date: DateTime.now().toIso8601String(),
              type: Value(isIncome ? 'income' : 'expense'),
              note: Value(_sourceNote(source)),
            ),
          );
    });
  }

  @override
  Future<void> insertReminder({
    required String title,
    required DateTime date,
    required String time,
    required String priority,
    required String category,
    required bool addToTodayTimeline,
    required DateTime? notifyAt,
    required QuickCaptureMode source,
  }) async {
    final dateIso = AppDateUtils.formatApiDate(date);

    // Planner item + timeline entry are written atomically.
    await _write('reminder', () async {
      await _db.transaction(() async {
        await _db
            .into(_db.plannerItems)
            .insert(
              PlannerItemsCompanion.insert(
                title: title,
                date: dateIso,
                startTime: Value(time),
                category: category,
                priority: Value(priority),
                colorValue: AppColors.moduleTime.toARGB32(),
                iconCodePoint: Icons.notifications_active_rounded.codePoint,
                notes: Value(_sourceNote(source)),
              ),
            );
        if (addToTodayTimeline) {
          await _db
              .into(_db.timelineItems)
              .insert(
                TimelineItemsCompanion.insert(
                  time: time,
                  title: title,
                  category: category,
                  colorValue: AppColors.moduleTime.toARGB32(),
                  iconCodePoint: Icons.notifications_active_rounded.codePoint,
                  action: 'Start',
                  date: dateIso,
                ),
              );
        }
      });
    });

    // The reminder is already persisted; a notification failure (e.g. OS
    // permission revoked) must not report the save as failed. It is logged
    // loudly instead of being swallowed.
    if (notifyAt != null) {
      try {
        await _notifications.scheduleNotification(
          id: Object.hash(title, notifyAt) & 0x7FFFFFFF,
          title: 'Reminder: $title',
          body: 'Scheduled for $time ($category)',
          scheduledDate: notifyAt,
        );
      } catch (error, stackTrace) {
        developer.log(
          'Reminder saved but notification scheduling failed',
          name: 'DailyLifeOS.QuickCapture',
          error: error,
          stackTrace: stackTrace,
          level: 900,
        );
      }
    }
  }

  @override
  Future<void> insertHabit({required String title, required String category}) {
    return _write('habit', () async {
      await _addHabit(
        HabitEntity(
          id: 0,
          title: title,
          description: StringConstants.quickCaptureHabitDescription,
          iconCodePoint: Icons.bolt_rounded.codePoint,
          colorValue: AppColors.primary.toARGB32(),
          streakDays: 0,
          isDoneToday: false,
          createdAt: DateTime.now().toIso8601String(),
          category: category,
          scheduleType: 'daily',
        ),
      );
    });
  }

  @override
  Future<void> insertNote({
    required String title,
    required String content,
    required String tag,
    required bool isPinned,
  }) {
    return _write('note', () async {
      final nowIso = DateTime.now().toIso8601String();
      await _db
          .into(_db.notes)
          .insert(
            NotesCompanion.insert(
              title: title,
              content: content,
              colorValue: AppColors.moduleNotes.toARGB32(),
              isPinned: Value(isPinned),
              tags: Value(tag),
              createdAt: nowIso,
              updatedAt: nowIso,
            ),
          );
    });
  }
}
