import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/quick_capture_entities.dart';
import '../../domain/repositories/quick_capture_repository.dart';
import '../datasources/quick_capture_local_datasource.dart';

class QuickCaptureRepositoryImpl implements QuickCaptureRepository {
  final QuickCaptureLocalDataSource _localDataSource;

  const QuickCaptureRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, Unit>> saveTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    required String paymentMode,
    required QuickCaptureMode source,
  }) {
    return guardRepositoryCall(
      context: 'QuickCapture.saveTransaction',
      () async {
        await _localDataSource.insertTransaction(
          title: title,
          amount: amount,
          isIncome: isIncome,
          category: category,
          paymentMode: paymentMode,
          source: source,
        );
        return unit;
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> saveReminder({
    required String title,
    required DateTime date,
    required String time,
    required String priority,
    required String category,
    required bool addToTodayTimeline,
    required DateTime? notifyAt,
    required QuickCaptureMode source,
  }) {
    return guardRepositoryCall(context: 'QuickCapture.saveReminder', () async {
      await _localDataSource.insertReminder(
        title: title,
        date: date,
        time: time,
        priority: priority,
        category: category,
        addToTodayTimeline: addToTodayTimeline,
        notifyAt: notifyAt,
        source: source,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> saveHabit({
    required String title,
    required String category,
  }) {
    return guardRepositoryCall(context: 'QuickCapture.saveHabit', () async {
      await _localDataSource.insertHabit(title: title, category: category);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> saveNote({
    required String title,
    required String content,
    required String tag,
    required bool isPinned,
  }) {
    return guardRepositoryCall(context: 'QuickCapture.saveNote', () async {
      await _localDataSource.insertNote(
        title: title,
        content: content,
        tag: tag,
        isPinned: isPinned,
      );
      return unit;
    });
  }
}
