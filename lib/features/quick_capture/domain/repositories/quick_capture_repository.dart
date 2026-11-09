import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/quick_capture_entities.dart';

/// Persistence boundary for Quick Capture. Every write returns
/// `Either<Failure, Unit>`; implementations never throw.
abstract class QuickCaptureRepository {
  Future<Either<Failure, Unit>> saveTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    required String paymentMode,
    required QuickCaptureMode source,
  });

  Future<Either<Failure, Unit>> saveReminder({
    required String title,
    required DateTime date,
    required String time,
    required String priority,
    required String category,
    required bool addToTodayTimeline,
    required DateTime? notifyAt,
    required QuickCaptureMode source,
  });

  Future<Either<Failure, Unit>> saveHabit({
    required String title,
    required String category,
  });

  Future<Either<Failure, Unit>> saveNote({
    required String title,
    required String content,
    required String tag,
    required bool isPinned,
  });
}
